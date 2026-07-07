# TextLens Next-Stage Retention Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the next retention layer for TextLens: setup guide, searchable/favorite history, better long-text result handling, menu bar recent results, and small recovery improvements.

**Architecture:** Keep the app local and menu-bar shaped. Extend `TranslationHistoryStore` first so UI work can depend on stable methods, then wire history into settings, result windows, and the menu. Add a small setup state model instead of turning `SettingsView` into a wizard framework.

**Tech Stack:** Swift 5.9, SwiftPM, macOS 13+, AppKit, SwiftUI, Foundation, XCTest.

## Global Constraints

- No account system.
- No cloud sync.
- No browser extensions.
- No team terminology libraries.
- No offline translation models.
- No complex tags or folders for history.
- No provider marketplace or plugin system.
- History and favorites remain local.
- No default telemetry; metrics come from dogfood sessions, beta feedback, or explicit opt-in local diagnostics.
- Keep existing checks passing: `rtk swift run TextLensChecks`.

---

## File Structure

- Modify: `Sources/TextLensCore/TranslationHistoryStore.swift`
  - Add favorite state, search, favorite filtering, favorite-safe retention, lookup by id, and export modes.
- Modify: `Tests/TextLensTests/TranslationHistoryStoreTests.swift`
  - Cover search, favorites, retention, disabled history, and export modes.
- Create: `Sources/TextLensCore/SetupGuideState.swift`
  - Pure state model for first-use guide progress.
- Create: `Tests/TextLensTests/SetupGuideStateTests.swift`
  - Cover setup completion transitions.
- Modify: `Sources/TextLens/ResultPopover.swift`
  - Preserve current popover, but make Expand open a richer result window with copy all, retry, and favorite.
- Modify: `Sources/TextLens/SelectionTranslator.swift`
  - Expose `translateText(_:)`, use the new `TranslationHistoryStore.add` return value, and pass favorite actions to the result UI.
- Modify: `Sources/TextLens/ScreenCaptureTranslator.swift`
  - Same result/favorite wiring for screenshot translations.
- Modify: `Sources/TextLens/AppShell.swift`
  - Add recent menu items and an Open History entry without hiding primary actions.
- Modify: `Sources/TextLens/SettingsView.swift`
  - Add setup guide mode, history search/favorite UI, favorites export, and advanced setting disclosure.

---

### Task 1: History Search, Favorites, And Export Modes

**Files:**
- Modify: `Sources/TextLensCore/TranslationHistoryStore.swift`
- Modify: `Tests/TextLensTests/TranslationHistoryStoreTests.swift`

**Interfaces:**
- Produces: `TranslationHistoryItem.isFavorite: Bool`
- Produces: `TranslationHistoryStore.add(original:translated:) -> TranslationHistoryItem`
- Produces: `TranslationHistoryStore.toggleFavorite(id: UUID) -> TranslationHistoryItem?`
- Produces: `TranslationHistoryStore.search(_ query: String, favoritesOnly: Bool = false) -> [TranslationHistoryItem]`
- Produces: `TranslationHistoryStore.item(id: UUID) -> TranslationHistoryItem?`
- Produces: `TranslationHistoryStore.exportText(favoritesOnly: Bool = false) -> String`

- [ ] **Step 1: Write failing tests for favorites, retention, search, disabled history, and export**

Add these tests to `Tests/TextLensTests/TranslationHistoryStoreTests.swift`:

```swift
func testSearchMatchesOriginalAndTranslationCaseInsensitively() {
    let defaults = UserDefaults(suiteName: UUID().uuidString)!
    let store = TranslationHistoryStore(defaults: defaults)
    store.add(original: "Hello world", translated: "你好世界")
    store.add(original: "Good morning", translated: "早上好")

    XCTAssertEqual(store.search("hello").map(\.original), ["Hello world"])
    XCTAssertEqual(store.search("早上").map(\.original), ["Good morning"])
}

func testFavoritesSurviveRecentHistoryLimit() {
    let defaults = UserDefaults(suiteName: UUID().uuidString)!
    let store = TranslationHistoryStore(defaults: defaults, limit: 2)
    let favorite = store.add(original: "keep", translated: "保留")
    _ = store.toggleFavorite(id: favorite.id)

    store.add(original: "one", translated: "一")
    store.add(original: "two", translated: "二")
    store.add(original: "three", translated: "三")

    XCTAssertTrue(store.items.contains { $0.id == favorite.id && $0.isFavorite })
    XCTAssertEqual(store.items.filter { !$0.isFavorite }.map(\.original), ["three", "two"])
}

func testFavoriteFilterAndExportFavoritesOnly() {
    let defaults = UserDefaults(suiteName: UUID().uuidString)!
    let store = TranslationHistoryStore(defaults: defaults)
    let first = store.add(original: "alpha", translated: "阿尔法")
    store.add(original: "beta", translated: "贝塔")
    _ = store.toggleFavorite(id: first.id)

    XCTAssertEqual(store.search("", favoritesOnly: true).map(\.original), ["alpha"])
    XCTAssertTrue(store.exportText(favoritesOnly: true).contains("alpha"))
    XCTAssertFalse(store.exportText(favoritesOnly: true).contains("beta"))
}

func testDisabledHistoryDoesNotAddNewNonFavoriteItems() {
    let defaults = UserDefaults(suiteName: UUID().uuidString)!
    let store = TranslationHistoryStore(defaults: defaults)
    let existing = store.add(original: "saved", translated: "已保存")
    _ = store.toggleFavorite(id: existing.id)

    store.isEnabled = false
    _ = store.add(original: "ignored", translated: "忽略")

    XCTAssertEqual(store.items.map(\.original), ["saved"])
    XCTAssertTrue(store.items[0].isFavorite)
}
```

- [ ] **Step 2: Run the focused tests and verify they fail**

Run:

```bash
rtk swift test --filter TranslationHistoryStoreTests
```

Expected: FAIL because `isFavorite`, `toggleFavorite`, `search`, and the new `add` return type do not exist.

- [ ] **Step 3: Implement the minimal history store changes**

Replace `Sources/TextLensCore/TranslationHistoryStore.swift` with:

```swift
import Foundation

public struct TranslationHistoryItem: Codable, Equatable, Identifiable {
    public let id: UUID
    public let date: Date
    public let original: String
    public let translated: String
    public let isFavorite: Bool

    public init(id: UUID = UUID(), date: Date = Date(), original: String, translated: String, isFavorite: Bool = false) {
        self.id = id
        self.date = date
        self.original = original
        self.translated = translated
        self.isFavorite = isFavorite
    }

    private enum CodingKeys: String, CodingKey {
        case id, date, original, translated, isFavorite
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        date = try container.decode(Date.self, forKey: .date)
        original = try container.decode(String.self, forKey: .original)
        translated = try container.decode(String.self, forKey: .translated)
        isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
    }
}

public final class TranslationHistoryStore {
    private enum Key {
        static let items = "translationHistoryItems"
        static let enabled = "translationHistoryEnabled"
    }

    private let defaults: UserDefaults
    private let limit: Int

    public init(defaults: UserDefaults = .standard, limit: Int = 20) {
        self.defaults = defaults
        self.limit = limit
    }

    public var isEnabled: Bool {
        get { defaults.object(forKey: Key.enabled) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.enabled) }
    }

    public var items: [TranslationHistoryItem] {
        get {
            guard let data = defaults.data(forKey: Key.items),
                  let items = try? JSONDecoder().decode([TranslationHistoryItem].self, from: data) else {
                return []
            }
            return items
        }
        set { save(trimmed(newValue)) }
    }

    @discardableResult
    public func add(original: String, translated: String) -> TranslationHistoryItem {
        let existing = items.first { $0.original == original && $0.translated == translated }
        let item = TranslationHistoryItem(original: original, translated: translated, isFavorite: existing?.isFavorite ?? false)
        guard isEnabled || item.isFavorite else { return item }
        items = [item] + items.filter { $0.original != original || $0.translated != translated }
        return item
    }

    public func item(id: UUID) -> TranslationHistoryItem? {
        items.first { $0.id == id }
    }

    public func toggleFavorite(id: UUID) -> TranslationHistoryItem? {
        var updated: TranslationHistoryItem?
        items = items.map { item in
            guard item.id == id else { return item }
            updated = TranslationHistoryItem(
                id: item.id,
                date: item.date,
                original: item.original,
                translated: item.translated,
                isFavorite: !item.isFavorite
            )
            return updated!
        }
        return updated
    }

    public func search(_ query: String, favoritesOnly: Bool = false) -> [TranslationHistoryItem] {
        let source = favoritesOnly ? items.filter(\.isFavorite) : items
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return source }
        return source.filter {
            $0.original.localizedCaseInsensitiveContains(trimmed)
                || $0.translated.localizedCaseInsensitiveContains(trimmed)
        }
    }

    public func clear() {
        defaults.removeObject(forKey: Key.items)
    }

    public func exportText(favoritesOnly: Bool = false) -> String {
        search("", favoritesOnly: favoritesOnly)
            .map { "Original:\n\($0.original)\n\nTranslation:\n\($0.translated)" }
            .joined(separator: "\n\n---\n\n")
    }

    private func trimmed(_ items: [TranslationHistoryItem]) -> [TranslationHistoryItem] {
        var keptRecent = 0
        return items.filter { item in
            if item.isFavorite { return true }
            guard keptRecent < limit else { return false }
            keptRecent += 1
            return true
        }
    }

    private func save(_ items: [TranslationHistoryItem]) {
        guard let data = try? JSONEncoder().encode(items) else { return }
        defaults.set(data, forKey: Key.items)
    }
}
```

- [ ] **Step 4: Run the history tests and verify they pass**

Run:

```bash
rtk swift test --filter TranslationHistoryStoreTests
```

Expected: PASS.

- [ ] **Step 5: Commit**

Run:

```bash
rtk git add Sources/TextLensCore/TranslationHistoryStore.swift Tests/TextLensTests/TranslationHistoryStoreTests.swift
rtk git commit -m "feat: add searchable favorite history"
```

---

### Task 2: Setup Guide State Model

**Files:**
- Create: `Sources/TextLensCore/SetupGuideState.swift`
- Create: `Tests/TextLensTests/SetupGuideStateTests.swift`

**Interfaces:**
- Consumes: `PermissionState`
- Produces: `SetupGuideState`
- Produces: `SetupGuideState.isComplete: Bool`

- [ ] **Step 1: Write failing setup state tests**

Create `Tests/TextLensTests/SetupGuideStateTests.swift`:

```swift
import XCTest
@testable import TextLensCore

final class SetupGuideStateTests: XCTestCase {
    func testIncompleteWhenPermissionsMissingAndNotSkipped() {
        let state = SetupGuideState(
            accessibility: .missing,
            screenRecording: .granted,
            skippedPermissions: false,
            targetLanguage: "Chinese",
            testedTranslationPath: true
        )

        XCTAssertFalse(state.isComplete)
    }

    func testCompleteWhenPermissionsSkippedLanguageSelectedAndProviderTested() {
        let state = SetupGuideState(
            accessibility: .missing,
            screenRecording: .missing,
            skippedPermissions: true,
            targetLanguage: "Chinese",
            testedTranslationPath: true
        )

        XCTAssertTrue(state.isComplete)
    }

    func testIncompleteWithoutTargetLanguageOrTranslationTest() {
        XCTAssertFalse(SetupGuideState(accessibility: .granted, screenRecording: .granted, skippedPermissions: false, targetLanguage: "", testedTranslationPath: true).isComplete)
        XCTAssertFalse(SetupGuideState(accessibility: .granted, screenRecording: .granted, skippedPermissions: false, targetLanguage: "Chinese", testedTranslationPath: false).isComplete)
    }
}
```

- [ ] **Step 2: Run the focused tests and verify they fail**

Run:

```bash
rtk swift test --filter SetupGuideStateTests
```

Expected: FAIL because `SetupGuideState` does not exist.

- [ ] **Step 3: Add the minimal pure state model**

Create `Sources/TextLensCore/SetupGuideState.swift`:

```swift
import Foundation

public struct SetupGuideState: Equatable {
    public let accessibility: PermissionState
    public let screenRecording: PermissionState
    public let skippedPermissions: Bool
    public let targetLanguage: String
    public let testedTranslationPath: Bool

    public init(
        accessibility: PermissionState,
        screenRecording: PermissionState,
        skippedPermissions: Bool,
        targetLanguage: String,
        testedTranslationPath: Bool
    ) {
        self.accessibility = accessibility
        self.screenRecording = screenRecording
        self.skippedPermissions = skippedPermissions
        self.targetLanguage = targetLanguage
        self.testedTranslationPath = testedTranslationPath
    }

    public var isComplete: Bool {
        let permissionsReady = skippedPermissions || (accessibility.isGranted && screenRecording.isGranted)
        return permissionsReady
            && !targetLanguage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && testedTranslationPath
    }
}
```

- [ ] **Step 4: Run the setup tests and verify they pass**

Run:

```bash
rtk swift test --filter SetupGuideStateTests
```

Expected: PASS.

- [ ] **Step 5: Commit**

Run:

```bash
rtk git add Sources/TextLensCore/SetupGuideState.swift Tests/TextLensTests/SetupGuideStateTests.swift
rtk git commit -m "feat: add setup guide state"
```

---

### Task 3: Rich Expanded Result Window

**Files:**
- Modify: `Sources/TextLens/ResultPopover.swift`
- Modify: `Sources/TextLens/SelectionTranslator.swift`
- Modify: `Sources/TextLens/ScreenCaptureTranslator.swift`

**Interfaces:**
- Consumes: `TranslationHistoryStore.add(original:translated:) -> TranslationHistoryItem`
- Consumes: `TranslationHistoryStore.toggleFavorite(id:) -> TranslationHistoryItem?`
- Produces: `ResultPopover.show(original:translated:anchor:backgroundOpacity:isLoading:retry:favorite:)`
- Produces: `SelectionTranslator.translateText(_ text: String)`

- [ ] **Step 1: Update `ResultPopover.show` signature and stored favorite action**

Change `Sources/TextLens/ResultPopover.swift` so the stored properties and `show` method include favorite support:

```swift
private var retryAction: (() -> Void)?
private var favoriteAction: (() -> Void)?

func show(
    original: String,
    translated: String,
    anchor: CGRect? = nil,
    backgroundOpacity: Double = 0.9,
    isLoading: Bool = false,
    retry: (() -> Void)? = nil,
    favorite: (() -> Void)? = nil
) {
    DispatchQueue.main.async { [weak self] in
        self?.present(
            original: original,
            translated: translated,
            anchor: anchor,
            backgroundOpacity: backgroundOpacity,
            isLoading: isLoading,
            retry: retry,
            favorite: favorite
        )
    }
}
```

Also update `present` to accept `favorite: (() -> Void)?` and assign:

```swift
retryAction = retry
favoriteAction = favorite
```

- [ ] **Step 2: Replace `expand()` with a richer window**

In `ResultPopover.swift`, replace the existing `expand()` method with:

```swift
@objc private func expand() {
    expandedWindow?.close()

    let content = NSView(frame: NSRect(x: 0, y: 0, width: 680, height: 500))

    let textView = NSTextView(frame: NSRect(x: 16, y: 56, width: 648, height: 428))
    textView.string = originalText.isEmpty ? translatedText : "Original:\n\(originalText)\n\nTranslation:\n\(translatedText)"
    textView.isEditable = false
    textView.isRichText = false
    textView.textContainerInset = NSSize(width: 10, height: 10)

    let scrollView = NSScrollView(frame: textView.frame)
    scrollView.documentView = textView
    scrollView.hasVerticalScroller = true
    scrollView.hasHorizontalScroller = false

    let copyButton = NSButton(frame: NSRect(x: 16, y: 16, width: 80, height: 28))
    copyButton.title = "Copy All"
    copyButton.target = self
    copyButton.action = #selector(copyTranslation)

    let retryButton = NSButton(frame: NSRect(x: 104, y: 16, width: 64, height: 28))
    retryButton.title = "Retry"
    retryButton.target = self
    retryButton.action = #selector(retryTranslation)
    retryButton.isEnabled = retryAction != nil

    let favoriteButton = NSButton(frame: NSRect(x: 176, y: 16, width: 80, height: 28))
    favoriteButton.title = "Favorite"
    favoriteButton.target = self
    favoriteButton.action = #selector(favoriteResult)
    favoriteButton.isEnabled = favoriteAction != nil

    content.addSubview(scrollView)
    content.addSubview(copyButton)
    content.addSubview(retryButton)
    content.addSubview(favoriteButton)

    let window = NSWindow(contentRect: content.frame, styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
    window.title = "TextLens Result"
    window.contentView = content
    window.center()
    window.makeKeyAndOrderFront(nil)
    expandedWindow = window
}

@objc private func favoriteResult() {
    favoriteAction?()
}
```

Also update `close()` to clear both action closures:

```swift
@objc private func close() {
    window?.orderOut(nil)
    window = nil
    retryAction = nil
    favoriteAction = nil
}
```

- [ ] **Step 3: Expose text translation and wire favorite actions after successful translations**

In `SelectionTranslator`, change the current private helper:

```swift
private func translate(text: String) {
```

to:

```swift
func translateText(_ text: String) {
```

Then update `translateClipboard()` and `translateSelection()` to call `translateText(...)`.

In `SelectionTranslator.translateText(_:)`, replace:

```swift
historyStore.add(original: text, translated: translated)
popover.show(original: text, translated: translated)
```

with:

```swift
let item = historyStore.add(original: text, translated: translated)
popover.show(
    original: text,
    translated: translated,
    retry: { [weak self] in self?.translateText(text) },
    favorite: { [weak historyStore] in _ = historyStore?.toggleFavorite(id: item.id) }
)
```

In `ScreenCaptureTranslator.translate(region:on:)`, replace:

```swift
historyStore.add(original: editedText, translated: translated)
popover.show(original: editedText, translated: translated, anchor: anchor, backgroundOpacity: popoverOpacity)
```

with:

```swift
let item = historyStore.add(original: editedText, translated: translated)
popover.show(
    original: editedText,
    translated: translated,
    anchor: anchor,
    backgroundOpacity: popoverOpacity,
    retry: { [weak self] in self?.retry(region: region, displayID: displayID) },
    favorite: { [weak historyStore] in _ = historyStore?.toggleFavorite(id: item.id) }
)
```

- [ ] **Step 4: Build and run checks**

Run:

```bash
rtk swift build --product TextLens
rtk swift run TextLensChecks
```

Expected: both commands complete successfully and `TextLensChecks` prints `ok`.

- [ ] **Step 5: Commit**

Run:

```bash
rtk git add Sources/TextLens/ResultPopover.swift Sources/TextLens/SelectionTranslator.swift Sources/TextLens/ScreenCaptureTranslator.swift
rtk git commit -m "feat: improve expanded translation results"
```

---

### Task 4: History Search, Favorites, And Export UI

**Files:**
- Modify: `Sources/TextLens/SettingsView.swift`

**Interfaces:**
- Consumes: `TranslationHistoryStore.search(_:favoritesOnly:)`
- Consumes: `TranslationHistoryStore.toggleFavorite(id:)`
- Consumes: `TranslationHistoryStore.exportText(favoritesOnly:)`

- [ ] **Step 1: Add state for history search and favorites filter**

In `SettingsView`, add state near the existing history state:

```swift
@State private var historySearch = ""
@State private var showingFavoritesOnly = false
```

Add this computed property near other helpers:

```swift
private var visibleHistoryItems: [TranslationHistoryItem] {
    historyStore.search(historySearch, favoritesOnly: showingFavoritesOnly)
}
```

- [ ] **Step 2: Replace the history list with searchable favorite controls**

In the `.history` page inside `content`, use this shape:

```swift
page("History") {
    Toggle("Save translation history", isOn: $historyEnabled)
    HStack {
        TextField("Search history", text: $historySearch)
            .textFieldStyle(.roundedBorder)
        Toggle("Favorites", isOn: $showingFavoritesOnly)
            .toggleStyle(.checkbox)
    }
    .frame(maxWidth: 520)

    if visibleHistoryItems.isEmpty {
        Text(historySearch.isEmpty ? "No history yet." : "No matching history.")
            .foregroundStyle(.secondary)
    } else {
        List(visibleHistoryItems) { item in
            VStack(alignment: .leading, spacing: 6) {
                Text(item.original)
                    .font(.headline)
                    .lineLimit(2)
                Text(item.translated)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                HStack {
                    Button(item.isFavorite ? "Unfavorite" : "Favorite") {
                        _ = historyStore.toggleFavorite(id: item.id)
                        historyItems = historyStore.items
                    }
                    Button("Copy Translation") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(item.translated, forType: .string)
                    }
                }
            }
        }
        .frame(height: 260)
    }

    HStack {
        Button("Clear History", action: clearHistory)
        Button("Export All", action: { exportHistory(favoritesOnly: false) })
        Button("Export Favorites", action: { exportHistory(favoritesOnly: true) })
            .disabled(!historyStore.items.contains { $0.isFavorite })
        Text(exportStatus).foregroundStyle(.secondary)
    }
}
```

- [ ] **Step 3: Update export function signature**

Replace `exportHistory()` with:

```swift
private func exportHistory(favoritesOnly: Bool) {
    let panel = NSSavePanel()
    panel.nameFieldStringValue = favoritesOnly ? "textlens-favorites.txt" : "textlens-history.txt"
    guard panel.runModal() == .OK, let url = panel.url else { return }
    do {
        try historyStore.exportText(favoritesOnly: favoritesOnly).write(to: url, atomically: true, encoding: .utf8)
        exportStatus = "Exported."
    } catch {
        exportStatus = error.localizedDescription
    }
}
```

- [ ] **Step 4: Update save and restore paths**

Keep the existing `save()` history setting write:

```swift
historyStore.isEnabled = historyEnabled
```

In `clearHistory()`, reset filters:

```swift
private func clearHistory() {
    historyStore.clear()
    historyItems = []
    historySearch = ""
    showingFavoritesOnly = false
    exportStatus = "Cleared."
}
```

- [ ] **Step 5: Build and run checks**

Run:

```bash
rtk swift build --product TextLens
rtk swift run TextLensChecks
```

Expected: both commands complete successfully and `TextLensChecks` prints `ok`.

- [ ] **Step 6: Commit**

Run:

```bash
rtk git add Sources/TextLens/SettingsView.swift
rtk git commit -m "feat: add history search and favorites UI"
```

---

### Task 5: Menu Bar Recent Results

**Files:**
- Modify: `Sources/TextLens/AppShell.swift`

**Interfaces:**
- Consumes: `TranslationHistoryStore.items`
- Consumes: `TranslationHistoryStore.isEnabled`
- Consumes: `SelectionTranslator.translateText(_:)`
- Consumes: `ResultPopover.show(original:translated:retry:favorite:)`

- [ ] **Step 1: Store menu and recent item lookup state**

In `AppShell`, add properties:

```swift
private var menu: NSMenu?
private var recentItemIDs: [NSMenuItem: UUID] = [:]
```

In `applicationDidFinishLaunching`, assign:

```swift
self.menu = menu
```

- [ ] **Step 2: Add menu rebuild helpers**

Add these methods to `AppShell`:

```swift
private func rebuildMenu(_ menu: NSMenu) {
    menu.removeAllItems()
    recentItemIDs.removeAll()

    menu.addItem(NSMenuItem(title: "Translate Selection", action: #selector(translateSelection), keyEquivalent: ""))
    menu.addItem(NSMenuItem(title: "Translate Clipboard", action: #selector(translateClipboard), keyEquivalent: ""))
    menu.addItem(NSMenuItem(title: "Screenshot Translate", action: #selector(screenshotTranslate), keyEquivalent: ""))

    if historyStore.isEnabled, !historyStore.items.isEmpty {
        menu.addItem(.separator())
        for item in historyStore.items.prefix(3) {
            let title = String(item.translated.prefix(40))
            let menuItem = NSMenuItem(title: title.isEmpty ? "Recent Translation" : title, action: #selector(openRecentResult(_:)), keyEquivalent: "")
            recentItemIDs[menuItem] = item.id
            menu.addItem(menuItem)
        }
        menu.addItem(NSMenuItem(title: "Open History", action: #selector(openSettings), keyEquivalent: ""))
    }

    menu.addItem(.separator())
    menu.addItem(NSMenuItem(title: "Settings", action: #selector(openSettings), keyEquivalent: ","))
    menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
}

@objc private func openRecentResult(_ sender: NSMenuItem) {
    guard let id = recentItemIDs[sender], let item = historyStore.item(id: id) else { return }
    popover.show(
        original: item.original,
        translated: item.translated,
        retry: { [weak self] in self?.selectionTranslator.translateText(item.original) },
        favorite: { [weak historyStore] in _ = historyStore?.toggleFavorite(id: item.id) }
    )
}
```

- [ ] **Step 3: Rebuild before menu open**

Replace `menuWillOpen` with:

```swift
func menuWillOpen(_ menu: NSMenu) {
    rebuildMenu(menu)
    updateStatus()
}
```

- [ ] **Step 4: Build and run checks**

Run:

```bash
rtk swift build --product TextLens
rtk swift run TextLensChecks
```

Expected: both commands complete successfully and `TextLensChecks` prints `ok`.

- [ ] **Step 5: Manual smoke test**

Run:

```bash
rtk scripts/run_app.sh
```

Expected:

- Primary menu actions remain visible.
- Recent items appear only when history is enabled and non-empty.
- Selecting a recent item opens the result without starting a new translation.

- [ ] **Step 6: Commit**

Run:

```bash
rtk git add Sources/TextLens/AppShell.swift
rtk git commit -m "feat: show recent translations in menu"
```

---

### Task 6: First-Use Setup Guide UI

**Files:**
- Modify: `Sources/TextLens/SettingsView.swift`
- Modify: `Sources/TextLens/AppShell.swift`

**Interfaces:**
- Consumes: `SetupGuideState`
- Consumes: `PermissionCenter.openAccessibilitySettings()`
- Consumes: `PermissionCenter.openScreenRecordingSettings()`
- Consumes: existing `testFreeProvider()`
- Produces: first-use setup UI that writes `settings.hasSeenOnboarding = true` only when complete or explicitly skipped.

- [ ] **Step 1: Add setup guide state to `SettingsView`**

Add these states:

```swift
@State private var showingSetupGuide: Bool
@State private var skippedSetupPermissions = false
@State private var testedSetupTranslationPath = false
```

Update `SettingsView.init` to initialize:

```swift
_showingSetupGuide = State(initialValue: !settings.hasSeenOnboarding)
```

Add:

```swift
private var setupGuideState: SetupGuideState {
    SetupGuideState(
        accessibility: permissionCenter.accessibility,
        screenRecording: permissionCenter.screenRecording,
        skippedPermissions: skippedSetupPermissions,
        targetLanguage: targetLanguage,
        testedTranslationPath: testedSetupTranslationPath
    )
}
```

- [ ] **Step 2: Show guide before normal settings content**

At the top of `body`, branch:

```swift
var body: some View {
    if showingSetupGuide {
        setupGuide
            .padding(24)
            .frame(width: 720, height: 520)
    } else {
        settingsBody
    }
}
```

Move the current body content into:

```swift
private var settingsBody: some View {
    HStack(spacing: 0) {
        List(Pane.allCases, selection: $selectedPane) { pane in
            Text(pane.rawValue).tag(pane)
        }
        .frame(width: 180)
        Divider()
        ScrollView {
            content
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    .frame(width: 880, height: 620)
}
```

- [ ] **Step 3: Add the minimal setup guide view**

Add this computed view inside `SettingsView`:

```swift
private var setupGuide: some View {
    VStack(alignment: .leading, spacing: 18) {
        Text("Set Up TextLens").font(.title.bold())
        Text("Finish the minimum setup for fast translation.")
            .foregroundStyle(.secondary)

        permissionRow("Accessibility", state: permissionCenter.accessibility, actionTitle: "Open Settings", action: permissionCenter.openAccessibilitySettings)
        permissionRow("Screen Recording", state: permissionCenter.screenRecording, actionTitle: "Open Settings", action: permissionCenter.openScreenRecordingSettings)

        Toggle("Skip permissions for now", isOn: $skippedSetupPermissions)

        formRow("Target Language") {
            Picker("", selection: $targetLanguage) {
                ForEach(SupportedLanguage.unitedNations.map(\.name), id: \.self) { language in
                    Text(SupportedLanguage.normalized(language).displayName).tag(language)
                }
            }
            .labelsHidden()
        }

        HStack {
            Button(testingFreeProvider ? "Testing..." : "Test Free Provider") {
                testedSetupTranslationPath = true
                testFreeProvider()
            }
            .disabled(testingFreeProvider)
            Text(freeProviderStatus).foregroundStyle(.secondary)
        }

        Spacer()

        HStack {
            Button("Finish Setup") {
                save()
                settings.hasSeenOnboarding = true
                showingSetupGuide = false
            }
            .disabled(!setupGuideState.isComplete)

            Button("Continue To Settings") {
                save()
                settings.hasSeenOnboarding = true
                showingSetupGuide = false
            }
        }
    }
}
```

- [ ] **Step 4: Stop AppShell from marking onboarding complete before the guide opens**

In `AppShell.openSettingsOnFirstLaunch`, replace:

```swift
settings.hasSeenOnboarding = true
```

with no assignment. The method should be:

```swift
private func openSettingsOnFirstLaunch() {
    guard !settings.hasSeenOnboarding else { return }
    DispatchQueue.main.async { [weak self] in
        self?.openSettings()
    }
}
```

- [ ] **Step 5: Build and run checks**

Run:

```bash
rtk swift build --product TextLens
rtk swift run TextLensChecks
```

Expected: both commands complete successfully and `TextLensChecks` prints `ok`.

- [ ] **Step 6: Commit**

Run:

```bash
rtk git add Sources/TextLens/SettingsView.swift Sources/TextLens/AppShell.swift
rtk git commit -m "feat: add first-use setup guide"
```

---

### Task 7: P1 Recovery And Settings Polish

**Files:**
- Modify: `Sources/TextLens/AppShell.swift`
- Modify: `Sources/TextLens/ScreenCaptureTranslator.swift`
- Modify: `Sources/TextLens/SettingsView.swift`

**Interfaces:**
- Consumes: existing shortcut registration result booleans.
- Produces: clearer shortcut conflict message.
- Produces: OCR confirmation Copy OCR Text and Reselect Region actions.
- Produces: simple advanced disclosure in settings.

- [ ] **Step 1: Improve shortcut conflict message**

In `AppShell.registerHotKeys`, replace:

```swift
settings.providerHealth = "Shortcut registration failed. Pick another key in Settings."
```

with:

```swift
let failed = [
    selectionRegistered ? nil : "Translate Selection",
    screenshotRegistered ? nil : "Screenshot Translate"
].compactMap { $0 }.joined(separator: ", ")
settings.providerHealth = "\(failed) shortcut failed. Choose another key in Settings."
```

- [ ] **Step 2: Add OCR copy and reselect actions**

In `ScreenCaptureTranslator.confirmOCRText(_:)`, change buttons to:

```swift
alert.addButton(withTitle: "Translate")
alert.addButton(withTitle: "Copy OCR Text")
alert.addButton(withTitle: "Reselect")
alert.addButton(withTitle: "Cancel")
```

Replace the return block with:

```swift
switch alert.runModal() {
case .alertFirstButtonReturn:
    return textView.string.trimmingCharacters(in: .whitespacesAndNewlines)
case .alertSecondButtonReturn:
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(textView.string, forType: .string)
    return nil
case NSApplication.ModalResponse(rawValue: NSApplication.ModalResponse.alertFirstButtonReturn.rawValue + 2):
    start()
    return nil
default:
    return nil
}
```

- [ ] **Step 3: Add advanced disclosure around API/provider comparison controls**

In `SettingsView`, add:

```swift
@State private var showingAdvancedSettings = false
```

Wrap API fallback/provider comparison controls with:

```swift
DisclosureGroup("Advanced Translation Settings", isExpanded: $showingAdvancedSettings) {
    VStack(alignment: .leading, spacing: 12) {
        Toggle("Use API when free translation fails", isOn: $useAPIFallback)
        formRow("API Base URL") { TextField("Base URL", text: $baseURL) }
        formRow("Model") { TextField("Model", text: $model) }
        formRow("API Key") { SecureField("Leave blank to keep saved key", text: $apiKey) }
        Button(testingAPI ? "Testing..." : "Test API", action: testAPI)
            .disabled(testingAPI)
        Text(apiStatus).foregroundStyle(.secondary)
    }
}
```

Keep the existing fields; this step only moves them under the disclosure instead of adding new settings.

- [ ] **Step 4: Build and run checks**

Run:

```bash
rtk swift build --product TextLens
rtk swift run TextLensChecks
```

Expected: both commands complete successfully and `TextLensChecks` prints `ok`.

- [ ] **Step 5: Commit**

Run:

```bash
rtk git add Sources/TextLens/AppShell.swift Sources/TextLens/ScreenCaptureTranslator.swift Sources/TextLens/SettingsView.swift
rtk git commit -m "feat: polish setup recovery paths"
```

---

## Final Verification

- [ ] **Step 1: Run unit tests**

Run:

```bash
rtk swift test
```

Expected: PASS. If the local CommandLineTools environment cannot find `XCTest`, record that environment failure and run the check target below.

- [ ] **Step 2: Run product checks**

Run:

```bash
rtk swift run TextLensChecks
```

Expected: prints `ok`.

- [ ] **Step 3: Build the app**

Run:

```bash
rtk swift build --product TextLens
```

Expected: build succeeds.

- [ ] **Step 4: Manual smoke test**

Run:

```bash
rtk scripts/run_app.sh
```

Expected:

- First launch opens setup guide when `hasSeenOnboarding` is false.
- Existing users can open Settings normally.
- History search finds original and translated text.
- Favorites survive normal history trimming.
- Expanded result window supports copy all, retry, and favorite.
- Menu bar recent entries appear only when history is enabled and non-empty.
- Shortcut conflict message names the failing shortcut.
- OCR confirmation offers Translate, Copy OCR Text, Reselect, and Cancel.
