# TextLens Minimal Refactor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the minimal effective refactor from the 2026-07-08 PRD: clearer setup completion, disabled no-op Settings actions, clearer screenshot selection hint, and less crowded result actions.

**Architecture:** Keep the current split: core state logic in `TextLensCore`, SwiftUI Settings in `SettingsView`, and AppKit selection/result windows in their existing files. Do not add dependencies or new UI frameworks. Prefer private computed properties and small layout helpers over new types.

**Tech Stack:** Swift 5.9, SwiftUI, AppKit, XCTest, Swift Package Manager.

## Global Constraints

- Reuse the existing SwiftUI Settings view and AppKit selection/result windows.
- Do not introduce a design system, visual reskin, or SwiftUI rewrite for the result popover.
- No new translation providers.
- No telemetry.
- No history model changes beyond button state behavior.
- Run `swift build` and `swift test` before completion.

---

## File Map

- Modify `Sources/TextLensCore/SetupGuideState.swift`: setup completion no longer requires a provider test.
- Modify `Tests/TextLensTests/SetupGuideStateTests.swift`: update setup completion expectations.
- Modify `Sources/TextLens/SettingsView.swift`: remove competing setup exit action, make Save dirty-aware, disable empty history actions.
- Modify `Sources/TextLens/RegionSelectionWindow.swift`: update selection hint copy and bubble sizing.
- Modify `Sources/TextLens/ResultPopover.swift`: keep AppKit, adjust button states/layout to avoid crowding.

---

### Task 1: Make Setup Completion Permission-Based

**Files:**
- Modify: `Sources/TextLensCore/SetupGuideState.swift`
- Modify: `Tests/TextLensTests/SetupGuideStateTests.swift`
- Modify: `Sources/TextLens/SettingsView.swift`

**Interfaces:**
- Consumes: `PermissionState.isGranted`, existing `SetupGuideState`.
- Produces: `SetupGuideState.isComplete: Bool` where completion requires permissions ready or skipped, plus non-empty target language. `testedTranslationPath` remains available for optional provider-test UI state.

- [ ] **Step 1: Update the failing setup tests first**

Replace `Tests/TextLensTests/SetupGuideStateTests.swift` with:

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
            testedTranslationPath: false
        )

        XCTAssertFalse(state.isComplete)
    }

    func testCompleteWhenPermissionsGrantedAndLanguageSelectedWithoutProviderTest() {
        let state = SetupGuideState(
            accessibility: .granted,
            screenRecording: .granted,
            skippedPermissions: false,
            targetLanguage: "Chinese",
            testedTranslationPath: false
        )

        XCTAssertTrue(state.isComplete)
    }

    func testCompleteWhenPermissionsSkippedAndLanguageSelectedWithoutProviderTest() {
        let state = SetupGuideState(
            accessibility: .missing,
            screenRecording: .missing,
            skippedPermissions: true,
            targetLanguage: "Chinese",
            testedTranslationPath: false
        )

        XCTAssertTrue(state.isComplete)
    }

    func testIncompleteWithoutTargetLanguage() {
        XCTAssertFalse(
            SetupGuideState(
                accessibility: .granted,
                screenRecording: .granted,
                skippedPermissions: false,
                targetLanguage: "",
                testedTranslationPath: false
            ).isComplete
        )
    }
}
```

- [ ] **Step 2: Run the targeted test and verify it fails**

Run: `swift test --filter SetupGuideStateTests`

Expected: FAIL because `testCompleteWhenPermissionsGrantedAndLanguageSelectedWithoutProviderTest` still requires `testedTranslationPath`.

- [ ] **Step 3: Implement the minimal core change**

In `Sources/TextLensCore/SetupGuideState.swift`, change `isComplete` to:

```swift
public var isComplete: Bool {
    let permissionsReady = skippedPermissions || (accessibility.isGranted && screenRecording.isGranted)
    return permissionsReady
        && !targetLanguage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
}
```

- [ ] **Step 4: Remove the competing setup exit action**

In `Sources/TextLens/SettingsView.swift`, replace the setup footer `HStack` with:

```swift
HStack {
    Spacer()
    Button("Finish Setup") {
        save()
        settings.hasSeenOnboarding = true
        showingSetupGuide = false
    }
    .disabled(!setupGuideState.isComplete)
}
```

Leave the `Test Free Provider` button in place and keep its status text.

- [ ] **Step 5: Run the task checks**

Run: `swift test --filter SetupGuideStateTests`

Expected: PASS.

Run: `swift build`

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add Sources/TextLensCore/SetupGuideState.swift Tests/TextLensTests/SetupGuideStateTests.swift Sources/TextLens/SettingsView.swift
git commit -m "fix: simplify setup completion"
```

---

### Task 2: Make Settings Actions Reflect Real State

**Files:**
- Modify: `Sources/TextLens/SettingsView.swift`

**Interfaces:**
- Consumes: `historyStore.items`, `historyStore.isEnabled`, `settings` values.
- Produces: private `hasHistoryItems: Bool`, `hasFavoriteHistoryItems: Bool`, and `hasUnsavedChanges: Bool` used by button disabled states.

- [ ] **Step 1: Add private state helpers**

In `Sources/TextLens/SettingsView.swift`, near `visibleHistoryItems`, add:

```swift
private var hasHistoryItems: Bool {
    !historyStore.items.isEmpty
}

private var hasFavoriteHistoryItems: Bool {
    historyStore.items.contains { $0.isFavorite }
}

private var hasUnsavedChanges: Bool {
    baseURL != settings.baseURL.absoluteString
        || model != settings.model
        || SupportedLanguage.normalized(targetLanguage).name != settings.targetLanguage
        || freeTranslationProvider != settings.freeTranslationProvider
        || !youdaoSecret.isEmpty
        || !baiduSecret.isEmpty
        || !apiKey.isEmpty
        || youdaoAppID != settings.youdaoAppID
        || baiduAppID != settings.baiduAppID
        || useAPIFallback != settings.useAPIFallback
        || clampedOpacity(screenshotPopoverOpacity) != settings.screenshotPopoverOpacity
        || selectionHotKey != settings.selectionHotKey
        || screenshotHotKey != settings.screenshotHotKey
        || historyEnabled != historyStore.isEnabled
        || glossaryText != settings.glossaryText
}
```

- [ ] **Step 2: Disable no-op history buttons**

In the History pane `HStack`, change the buttons to:

```swift
Button("Clear History") { clearHistory() }
    .disabled(!hasHistoryItems)
Button("Export All") { exportHistory(favoritesOnly: false) }
    .disabled(!hasHistoryItems)
Button("Export Favorites") { exportHistory(favoritesOnly: true) }
    .disabled(!hasFavoriteHistoryItems)
```

- [ ] **Step 3: Make Save only look actionable when dirty**

Replace `actionsSection` with:

```swift
private var actionsSection: some View {
    HStack {
        Spacer()
        Button(hasUnsavedChanges ? "Save" : "Saved") { save() }
            .disabled(!hasUnsavedChanges)
        Button("Restore Defaults") { restoreDefaults() }
    }
}
```

- [ ] **Step 4: Remove stale saved state**

Delete:

```swift
@State private var saved = false
```

Delete every `.onChange` modifier whose only body is:

```swift
{ _ in saved = false }
```

In `save()`, replace:

```swift
saved = saveModel.save(
```

with:

```swift
_ = saveModel.save(
```

In `restoreDefaults()`, delete:

```swift
saved = false
```

- [ ] **Step 5: Run the task check**

Run: `swift build`

Expected: PASS.

- [ ] **Step 6: Manual smoke check**

Launch the app with the existing script if desired:

```bash
scripts/run_app.sh
```

Expected: empty history shows disabled `Clear History` and `Export All`; unchanged Settings shows `Saved` disabled; changing one setting shows enabled `Save`.

- [ ] **Step 7: Commit**

```bash
git add Sources/TextLens/SettingsView.swift
git commit -m "fix: disable no-op settings actions"
```

---

### Task 3: Clarify Screenshot Selection Hint

**Files:**
- Modify: `Sources/TextLens/RegionSelectionWindow.swift`

**Interfaces:**
- Consumes: existing `RegionSelectionView.drawCancelHint()`.
- Produces: overlay hint text `Drag to select, Esc to cancel`.

- [ ] **Step 1: Change the hint text**

In `drawCancelHint()`, change:

```swift
let text = "Esc to cancel"
```

to:

```swift
let text = "Drag to select, Esc to cancel"
```

The existing text-size-based bubble calculation should expand automatically.

- [ ] **Step 2: Run the task check**

Run: `swift build`

Expected: PASS.

- [ ] **Step 3: Manual smoke check**

Trigger Screenshot Translate.

Expected: the overlay shows `Drag to select, Esc to cancel`; dragging still selects; Escape still cancels.

- [ ] **Step 4: Commit**

```bash
git add Sources/TextLens/RegionSelectionWindow.swift
git commit -m "fix: clarify screenshot selection hint"
```

---

### Task 4: Reduce Result Action Crowding Without Rewriting AppKit

**Files:**
- Modify: `Sources/TextLens/ResultPopover.swift`

**Interfaces:**
- Consumes: existing `copyOriginal`, `copyTranslation`, `copyAll`, `retryTranslation`, `expand`, `favoriteResult`, `close`.
- Produces: same actions with less crowded frames and accurate disabled states.

- [ ] **Step 1: Add a tiny button helper inside `ResultPopover`**

Add this private method near the `@objc` methods:

```swift
private func button(_ title: String, frame: NSRect, action: Selector, enabled: Bool = true) -> NSButton {
    let button = NSButton(frame: frame)
    button.title = title
    button.target = self
    button.action = action
    button.isEnabled = enabled
    return button
}
```

- [ ] **Step 2: Replace crowded popover button creation**

In `present(...)`, replace the five popover button blocks with:

```swift
let copyOriginalButton = button(
    "Copy Original",
    frame: NSRect(x: 12, y: 12, width: 104, height: 24),
    action: #selector(copyOriginal),
    enabled: !original.isEmpty
)
let copyTranslationButton = button(
    "Copy Translation",
    frame: NSRect(x: 124, y: 12, width: 124, height: 24),
    action: #selector(copyTranslation),
    enabled: !isLoading && !translated.isEmpty
)
let retryButton = button(
    "Retry",
    frame: NSRect(x: 256, y: 12, width: 48, height: 24),
    action: #selector(retryTranslation),
    enabled: retry != nil && !isLoading
)
let expandButton = button(
    "Expand",
    frame: NSRect(x: 308, y: 12, width: 56, height: 24),
    action: #selector(expand),
    enabled: !isLoading && (!original.isEmpty || !translated.isEmpty)
)
let closeButton = button(
    "Close",
    frame: NSRect(x: 368, y: 12, width: 28, height: 24),
    action: #selector(close)
)
```

- [ ] **Step 3: Widen the expanded result action row**

In `expand()`, replace the three expanded button blocks with:

```swift
let copyButton = button(
    "Copy All",
    frame: NSRect(x: 16, y: 16, width: 88, height: 28),
    action: #selector(copyAll),
    enabled: !originalText.isEmpty || !translatedText.isEmpty
)

let retryButton = button(
    "Retry",
    frame: NSRect(x: 112, y: 16, width: 72, height: 28),
    action: #selector(retryTranslation),
    enabled: retryAction != nil
)

let favoriteButton = button(
    "Favorite",
    frame: NSRect(x: 192, y: 16, width: 88, height: 28),
    action: #selector(favoriteResult),
    enabled: favoriteAction != nil
)
```

- [ ] **Step 4: Run the task check**

Run: `swift build`

Expected: PASS.

- [ ] **Step 5: Manual smoke check**

Show a normal translation result, a loading result, and an expanded result.

Expected: copy buttons are disabled when their text is empty; retry is disabled while loading or missing; expanded action buttons are readable at the default window size.

- [ ] **Step 6: Commit**

```bash
git add Sources/TextLens/ResultPopover.swift
git commit -m "fix: tidy result action buttons"
```

---

## Final Verification

- [ ] Run: `swift build`

Expected: PASS.

- [ ] Run: `swift test`

Expected: PASS.

- [ ] Manual release check:

```text
Fresh launch setup can be completed after permissions are ready.
Optional free provider test still runs and reports status.
Empty history shows disabled Clear History and Export All.
Unsaved Settings changes visibly enable Save; saving disables it again.
Screenshot selection hint reads Drag to select, Esc to cancel.
Result and expanded result buttons do not overlap at default sizes.
```

---

## Self-Review

- Spec coverage: all PRD sections map to Tasks 1-4.
- Placeholder scan: no placeholder markers or deferred implementation steps.
- Type consistency: all referenced symbols already exist except private helpers introduced in Task 2 and Task 4.
