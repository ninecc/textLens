# TextLens macOS Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a minimal native macOS menu bar app that translates selected text and selected screenshot regions through Apple Vision OCR and an OpenAI-compatible API.

**Architecture:** Use a Swift Package with one executable target for the menu bar app and one test target for core services. Keep platform services thin: settings, Keychain, translation HTTP, OCR, screenshot selection, and the floating result window are separate files with small interfaces.

**Tech Stack:** Swift 5.9+, Swift Package Manager, AppKit, SwiftUI, Vision, ScreenCaptureKit/CoreGraphics where needed, XCTest, URLProtocol-based HTTP tests.

---

## File Structure

- Create `Package.swift`: SwiftPM package definition.
- Create `Sources/TextLens/main.swift`: app entry point.
- Create `Sources/TextLens/AppShell.swift`: menu bar app lifecycle and menu commands.
- Create `Sources/TextLens/SettingsStore.swift`: `UserDefaults`-backed non-sensitive settings.
- Create `Sources/TextLens/KeychainStore.swift`: API key storage.
- Create `Sources/TextLens/TranslationService.swift`: OpenAI-compatible translation client.
- Create `Sources/TextLens/SelectionTranslator.swift`: selected text and clipboard translation flow.
- Create `Sources/TextLens/OCRService.swift`: Apple Vision OCR wrapper.
- Create `Sources/TextLens/ScreenCaptureTranslator.swift`: screenshot-selection flow.
- Create `Sources/TextLens/RegionSelectionWindow.swift`: transparent drag-selection overlay.
- Create `Sources/TextLens/ResultPopover.swift`: floating result window.
- Create `Sources/TextLens/SettingsView.swift`: settings UI.
- Create `Tests/TextLensTests/SettingsStoreTests.swift`: settings tests.
- Create `Tests/TextLensTests/TranslationServiceTests.swift`: translation HTTP tests.
- Create `Tests/TextLensTests/TestURLProtocol.swift`: test HTTP stub.

## Task 1: Swift Package Skeleton

**Files:**
- Create: `Package.swift`
- Create: `Sources/TextLens/main.swift`
- Create: `Sources/TextLens/AppShell.swift`

- [ ] **Step 1: Create package manifest**

```swift
// Package.swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TextLens",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "TextLens", targets: ["TextLens"])
    ],
    targets: [
        .executableTarget(name: "TextLens"),
        .testTarget(name: "TextLensTests", dependencies: ["TextLens"])
    ]
)
```

- [ ] **Step 2: Add app entry point**

```swift
// Sources/TextLens/main.swift
import AppKit

let app = NSApplication.shared
let delegate = AppShell()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
```

- [ ] **Step 3: Add minimal menu bar shell**

```swift
// Sources/TextLens/AppShell.swift
import AppKit

final class AppShell: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "TextLens"

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Translate Selection", action: #selector(translateSelection), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Translate Clipboard", action: #selector(translateClipboard), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Screenshot Translate", action: #selector(screenshotTranslate), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Settings", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))

        item.menu = menu
        statusItem = item
    }

    @objc private func translateSelection() {}
    @objc private func translateClipboard() {}
    @objc private func screenshotTranslate() {}
    @objc private func openSettings() {}

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}
```

- [ ] **Step 4: Build**

Run: `swift build`

Expected: build succeeds and produces `.build/debug/TextLens`.

- [ ] **Step 5: Commit**

```bash
git add Package.swift Sources/TextLens/main.swift Sources/TextLens/AppShell.swift
git commit -m "chore: add TextLens macOS package skeleton"
```

## Task 2: Settings Store

**Files:**
- Create: `Sources/TextLens/SettingsStore.swift`
- Create: `Tests/TextLensTests/SettingsStoreTests.swift`

- [ ] **Step 1: Write settings tests**

```swift
// Tests/TextLensTests/SettingsStoreTests.swift
import XCTest
@testable import TextLens

final class SettingsStoreTests: XCTestCase {
    func testDefaults() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let store = SettingsStore(defaults: defaults)

        XCTAssertEqual(store.baseURL, URL(string: "https://api.openai.com/v1/chat/completions")!)
        XCTAssertEqual(store.model, "gpt-4o-mini")
        XCTAssertEqual(store.targetLanguage, "Chinese")
    }

    func testReadWrite() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let store = SettingsStore(defaults: defaults)

        store.baseURL = URL(string: "https://example.com/v1/chat/completions")!
        store.model = "test-model"
        store.targetLanguage = "Japanese"

        XCTAssertEqual(store.baseURL.absoluteString, "https://example.com/v1/chat/completions")
        XCTAssertEqual(store.model, "test-model")
        XCTAssertEqual(store.targetLanguage, "Japanese")
    }
}
```

- [ ] **Step 2: Run failing test**

Run: `swift test --filter SettingsStoreTests`

Expected: fail because `SettingsStore` does not exist.

- [ ] **Step 3: Implement settings store**

```swift
// Sources/TextLens/SettingsStore.swift
import Foundation

final class SettingsStore {
    private enum Key {
        static let baseURL = "baseURL"
        static let model = "model"
        static let targetLanguage = "targetLanguage"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var baseURL: URL {
        get {
            if let value = defaults.string(forKey: Key.baseURL), let url = URL(string: value) {
                return url
            }
            return URL(string: "https://api.openai.com/v1/chat/completions")!
        }
        set { defaults.set(newValue.absoluteString, forKey: Key.baseURL) }
    }

    var model: String {
        get { defaults.string(forKey: Key.model) ?? "gpt-4o-mini" }
        set { defaults.set(newValue, forKey: Key.model) }
    }

    var targetLanguage: String {
        get { defaults.string(forKey: Key.targetLanguage) ?? "Chinese" }
        set { defaults.set(newValue, forKey: Key.targetLanguage) }
    }
}
```

- [ ] **Step 4: Run passing test**

Run: `swift test --filter SettingsStoreTests`

Expected: pass.

- [ ] **Step 5: Commit**

```bash
git add Sources/TextLens/SettingsStore.swift Tests/TextLensTests/SettingsStoreTests.swift
git commit -m "feat: add settings store"
```

## Task 3: Translation Service

**Files:**
- Create: `Sources/TextLens/TranslationService.swift`
- Create: `Tests/TextLensTests/TestURLProtocol.swift`
- Create: `Tests/TextLensTests/TranslationServiceTests.swift`

- [ ] **Step 1: Write URLProtocol stub**

```swift
// Tests/TextLensTests/TestURLProtocol.swift
import Foundation

final class TestURLProtocol: URLProtocol {
    static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
```

- [ ] **Step 2: Write translation tests**

```swift
// Tests/TextLensTests/TranslationServiceTests.swift
import XCTest
@testable import TextLens

final class TranslationServiceTests: XCTestCase {
    override func tearDown() {
        TestURLProtocol.handler = nil
        super.tearDown()
    }

    func testTranslateParsesResponse() async throws {
        let session = makeSession()
        let service = TranslationService(session: session)
        let url = URL(string: "https://example.com/v1/chat/completions")!

        TestURLProtocol.handler = { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer key")
            let body = try JSONSerialization.jsonObject(with: request.httpBody!) as! [String: Any]
            XCTAssertEqual(body["model"] as? String, "model")

            let data = """
            {"choices":[{"message":{"content":"你好"}}]}
            """.data(using: .utf8)!
            return (HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!, data)
        }

        let output = try await service.translate(
            text: "hello",
            targetLanguage: "Chinese",
            config: .init(baseURL: url, apiKey: "key", model: "model")
        )

        XCTAssertEqual(output, "你好")
    }

    func testTranslateThrowsOnAPIError() async {
        let session = makeSession()
        let service = TranslationService(session: session)
        let url = URL(string: "https://example.com/v1/chat/completions")!

        TestURLProtocol.handler = { request in
            let data = #"{"error":{"message":"bad key"}}"#.data(using: .utf8)!
            return (HTTPURLResponse(url: url, statusCode: 401, httpVersion: nil, headerFields: nil)!, data)
        }

        do {
            _ = try await service.translate(
                text: "hello",
                targetLanguage: "Chinese",
                config: .init(baseURL: url, apiKey: "bad", model: "model")
            )
            XCTFail("Expected API error")
        } catch let error as TranslationService.Error {
            XCTAssertEqual(error.localizedDescription, "bad key")
        } catch {
            XCTFail("Unexpected error: \\(error)")
        }
    }

    private func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [TestURLProtocol.self]
        return URLSession(configuration: config)
    }
}
```

- [ ] **Step 3: Run failing tests**

Run: `swift test --filter TranslationServiceTests`

Expected: fail because `TranslationService` does not exist.

- [ ] **Step 4: Implement translation service**

```swift
// Sources/TextLens/TranslationService.swift
import Foundation

final class TranslationService {
    struct Config {
        let baseURL: URL
        let apiKey: String
        let model: String
    }

    enum Error: LocalizedError, Equatable {
        case api(String)
        case malformedResponse

        var errorDescription: String? {
            switch self {
            case .api(let message): return message
            case .malformedResponse: return "Translation response was not readable."
            }
        }
    }

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func translate(text: String, targetLanguage: String, config: Config) async throws -> String {
        var request = URLRequest(url: config.baseURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \\(config.apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(ChatRequest(
            model: config.model,
            messages: [
                .init(role: "system", content: "Translate the user's text into \\(targetLanguage). Return only the translation."),
                .init(role: "user", content: text)
            ]
        ))

        let (data, response) = try await session.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0

        if !(200..<300).contains(status) {
            if let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                throw Error.api(apiError.error.message)
            }
            throw Error.api("Translation request failed with status \\(status).")
        }

        guard let output = try? JSONDecoder().decode(ChatResponse.self, from: data),
              let content = output.choices.first?.message.content,
              !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw Error.malformedResponse
        }

        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private struct ChatRequest: Encodable {
    let model: String
    let messages: [Message]

    struct Message: Encodable {
        let role: String
        let content: String
    }
}

private struct ChatResponse: Decodable {
    let choices: [Choice]

    struct Choice: Decodable {
        let message: Message
    }

    struct Message: Decodable {
        let content: String
    }
}

private struct APIErrorResponse: Decodable {
    let error: APIError

    struct APIError: Decodable {
        let message: String
    }
}
```

- [ ] **Step 5: Run passing tests**

Run: `swift test --filter TranslationServiceTests`

Expected: pass.

- [ ] **Step 6: Commit**

```bash
git add Sources/TextLens/TranslationService.swift Tests/TextLensTests/TestURLProtocol.swift Tests/TextLensTests/TranslationServiceTests.swift
git commit -m "feat: add OpenAI-compatible translation service"
```

## Task 4: Keychain API Key Storage

**Files:**
- Create: `Sources/TextLens/KeychainStore.swift`

- [ ] **Step 1: Implement small Keychain wrapper**

```swift
// Sources/TextLens/KeychainStore.swift
import Foundation
import Security

final class KeychainStore {
    private let service = "TextLens"
    private let account = "translation-api-key"

    var apiKey: String {
        get { read() ?? "" }
        set { save(newValue) }
    }

    private func read() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    private func save(_ value: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let update: [String: Any] = [kSecValueData as String: data]

        if SecItemUpdate(query as CFDictionary, update as CFDictionary) == errSecItemNotFound {
            var insert = query
            insert[kSecValueData as String] = data
            SecItemAdd(insert as CFDictionary, nil)
        }
    }
}
```

- [ ] **Step 2: Build**

Run: `swift build`

Expected: pass.

- [ ] **Step 3: Commit**

```bash
git add Sources/TextLens/KeychainStore.swift
git commit -m "feat: store API key in Keychain"
```

## Task 5: Wire Selection and Clipboard Translation

**Files:**
- Create: `Sources/TextLens/SelectionTranslator.swift`
- Modify: `Sources/TextLens/AppShell.swift`

- [ ] **Step 1: Implement selection translator**

```swift
// Sources/TextLens/SelectionTranslator.swift
import AppKit

@MainActor
final class SelectionTranslator {
    private let settings: SettingsStore
    private let keychain: KeychainStore
    private let translation: TranslationService
    private let popover: ResultPopover

    init(settings: SettingsStore, keychain: KeychainStore, translation: TranslationService, popover: ResultPopover) {
        self.settings = settings
        self.keychain = keychain
        self.translation = translation
        self.popover = popover
    }

    func translateClipboard() {
        let text = NSPasteboard.general.string(forType: .string) ?? ""
        translate(text: text)
    }

    func translateSelection() {
        if let text = selectedText(), !text.isEmpty {
            translate(text: text)
        } else {
            popover.show(original: "", translated: "Could not read selection. Copy text, then use Translate Clipboard.", canRetry: false)
        }
    }

    private func selectedText() -> String? {
        guard AXIsProcessTrusted() else { return nil }
        // ponytail: AX selected text varies by app; clipboard fallback is the first-version escape hatch.
        let systemWide = AXUIElementCreateSystemWide()
        var focused: AnyObject?
        guard AXUIElementCopyAttributeValue(systemWide, kAXFocusedUIElementAttribute as CFString, &focused) == .success,
              let element = focused else {
            return nil
        }

        var selected: AnyObject?
        guard AXUIElementCopyAttributeValue(element as! AXUIElement, kAXSelectedTextAttribute as CFString, &selected) == .success else {
            return nil
        }
        return selected as? String
    }

    private func translate(text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            popover.show(original: "", translated: "No text to translate.", canRetry: false)
            return
        }
        guard !keychain.apiKey.isEmpty else {
            popover.show(original: text, translated: "Missing API key. Open Settings.", canRetry: false)
            return
        }

        Task {
            do {
                let translated = try await translation.translate(
                    text: text,
                    targetLanguage: settings.targetLanguage,
                    config: .init(baseURL: settings.baseURL, apiKey: keychain.apiKey, model: settings.model)
                )
                popover.show(original: text, translated: translated, canRetry: false)
            } catch {
                popover.show(original: text, translated: error.localizedDescription, canRetry: true)
            }
        }
    }
}
```

- [ ] **Step 2: Add minimal result popover needed by translator**

Create `Sources/TextLens/ResultPopover.swift` with the code from Task 6 before building this task.

- [ ] **Step 3: Wire menu actions**

Replace `AppShell` with:

```swift
// Sources/TextLens/AppShell.swift
import AppKit

final class AppShell: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private let settings = SettingsStore()
    private let keychain = KeychainStore()
    private let translation = TranslationService()
    private let popover = ResultPopover()
    private lazy var selectionTranslator = SelectionTranslator(
        settings: settings,
        keychain: keychain,
        translation: translation,
        popover: popover
    )

    func applicationDidFinishLaunching(_ notification: Notification) {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "TextLens"

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Translate Selection", action: #selector(translateSelection), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Translate Clipboard", action: #selector(translateClipboard), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Screenshot Translate", action: #selector(screenshotTranslate), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Settings", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
        item.menu = menu
        statusItem = item
    }

    @objc private func translateSelection() { selectionTranslator.translateSelection() }
    @objc private func translateClipboard() { selectionTranslator.translateClipboard() }
    @objc private func screenshotTranslate() {}
    @objc private func openSettings() {}
    @objc private func quit() { NSApplication.shared.terminate(nil) }
}
```

- [ ] **Step 4: Build**

Run: `swift build`

Expected: pass.

- [ ] **Step 5: Commit**

```bash
git add Sources/TextLens/AppShell.swift Sources/TextLens/SelectionTranslator.swift
git commit -m "feat: wire selection and clipboard translation"
```

## Task 6: Result Popover

**Files:**
- Create: `Sources/TextLens/ResultPopover.swift`

- [ ] **Step 1: Implement popover window**

```swift
// Sources/TextLens/ResultPopover.swift
import AppKit

@MainActor
final class ResultPopover {
    private var window: NSWindow?
    private var translatedText = ""

    func show(original: String, translated: String, canRetry: Bool) {
        translatedText = translated

        let textView = NSTextView(frame: NSRect(x: 12, y: 44, width: 376, height: 180))
        textView.isEditable = false
        textView.string = original.isEmpty ? translated : "Original:\\n\\(original)\\n\\nTranslation:\\n\\(translated)"

        let copyButton = NSButton(frame: NSRect(x: 12, y: 12, width: 80, height: 24))
        copyButton.title = "Copy"
        copyButton.target = self
        copyButton.action = #selector(copyTranslation)

        let closeButton = NSButton(frame: NSRect(x: 308, y: 12, width: 80, height: 24))
        closeButton.title = "Close"
        closeButton.target = self
        closeButton.action = #selector(close)

        let content = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 236))
        content.addSubview(textView)
        content.addSubview(copyButton)
        content.addSubview(closeButton)

        let point = NSEvent.mouseLocation
        let frame = NSRect(x: point.x + 12, y: point.y - 236, width: 400, height: 236)
        let window = NSWindow(contentRect: frame, styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.level = .floating
        window.contentView = content
        window.makeKeyAndOrderFront(nil)
        self.window = window
    }

    @objc private func copyTranslation() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(translatedText, forType: .string)
    }

    @objc private func close() {
        window?.close()
        window = nil
    }
}
```

- [ ] **Step 2: Build**

Run: `swift build`

Expected: pass.

- [ ] **Step 3: Commit**

```bash
git add Sources/TextLens/ResultPopover.swift
git commit -m "feat: show translation result popover"
```

## Task 7: OCR Service

**Files:**
- Create: `Sources/TextLens/OCRService.swift`

- [ ] **Step 1: Implement Vision OCR wrapper**

```swift
// Sources/TextLens/OCRService.swift
import AppKit
import Vision

final class OCRService {
    enum Error: LocalizedError {
        case invalidImage

        var errorDescription: String? {
            switch self {
            case .invalidImage: return "Screenshot could not be read."
            }
        }
    }

    func recognizeText(in image: NSImage) async throws -> String {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw Error.invalidImage
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let text = (request.results as? [VNRecognizedTextObservation])?
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: "\\n") ?? ""
                continuation.resume(returning: text.trimmingCharacters(in: .whitespacesAndNewlines))
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            do {
                try VNImageRequestHandler(cgImage: cgImage).perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
```

- [ ] **Step 2: Build**

Run: `swift build`

Expected: pass.

- [ ] **Step 3: Commit**

```bash
git add Sources/TextLens/OCRService.swift
git commit -m "feat: add Vision OCR service"
```

## Task 8: Screenshot Translation Flow

**Files:**
- Create: `Sources/TextLens/ScreenCaptureTranslator.swift`
- Create: `Sources/TextLens/RegionSelectionWindow.swift`
- Modify: `Sources/TextLens/AppShell.swift`

- [ ] **Step 1: Implement region selection overlay**

```swift
// Sources/TextLens/RegionSelectionWindow.swift
import AppKit

@MainActor
final class RegionSelectionWindow: NSWindow {
    private let selectionView: RegionSelectionView

    init(screen: NSScreen, onSelect: @escaping (CGRect?) -> Void) {
        selectionView = RegionSelectionView(frame: screen.frame, onSelect: onSelect)
        super.init(contentRect: screen.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        level = .screenSaver
        backgroundColor = .clear
        isOpaque = false
        ignoresMouseEvents = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        contentView = selectionView
    }
}

private final class RegionSelectionView: NSView {
    private let onSelect: (CGRect?) -> Void
    private var start: CGPoint?
    private var current: CGPoint?

    init(frame: CGRect, onSelect: @escaping (CGRect?) -> Void) {
        self.onSelect = onSelect
        super.init(frame: frame)
        wantsLayer = true
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func mouseDown(with event: NSEvent) {
        start = convert(event.locationInWindow, from: nil)
        current = start
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        current = convert(event.locationInWindow, from: nil)
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        current = convert(event.locationInWindow, from: nil)
        guard let start, let current else {
            onSelect(nil)
            return
        }
        let rect = CGRect(
            x: min(start.x, current.x),
            y: min(start.y, current.y),
            width: abs(start.x - current.x),
            height: abs(start.y - current.y)
        )
        onSelect(rect.width < 8 || rect.height < 8 ? nil : rect)
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            onSelect(nil)
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.black.withAlphaComponent(0.25).setFill()
        bounds.fill()

        guard let start, let current else { return }
        let rect = CGRect(
            x: min(start.x, current.x),
            y: min(start.y, current.y),
            width: abs(start.x - current.x),
            height: abs(start.y - current.y)
        )
        NSColor.clear.setFill()
        rect.fill(using: .copy)
        NSColor.systemBlue.setStroke()
        NSBezierPath(rect: rect).stroke()
    }
}
```

- [ ] **Step 2: Implement screenshot translator**

```swift
// Sources/TextLens/ScreenCaptureTranslator.swift
import AppKit

@MainActor
final class ScreenCaptureTranslator {
    private let settings: SettingsStore
    private let keychain: KeychainStore
    private let ocr: OCRService
    private let translation: TranslationService
    private let popover: ResultPopover
    private var selectionWindow: RegionSelectionWindow?

    init(settings: SettingsStore, keychain: KeychainStore, ocr: OCRService, translation: TranslationService, popover: ResultPopover) {
        self.settings = settings
        self.keychain = keychain
        self.ocr = ocr
        self.translation = translation
        self.popover = popover
    }

    func start() {
        guard CGPreflightScreenCaptureAccess() else {
            CGRequestScreenCaptureAccess()
            popover.show(original: "", translated: "Screen Recording permission is required.", canRetry: false)
            return
        }

        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(NSEvent.mouseLocation) }) else {
            popover.show(original: "", translated: "Could not find the current screen.", canRetry: false)
            return
        }

        let window = RegionSelectionWindow(screen: screen) { [weak self] rect in
            Task { @MainActor in
                self?.selectionWindow?.close()
                self?.selectionWindow = nil
                guard let rect else { return }
                self?.translate(region: rect, on: screen)
            }
        }
        selectionWindow = window
        window.makeKeyAndOrderFront(nil)
    }

    private func translate(region: CGRect, on screen: NSScreen) {
        guard let image = capture(region: region, on: screen) else {
            popover.show(original: "", translated: "Could not capture the selected region.", canRetry: false)
            return
        }

        Task {
            do {
                let text = try await ocr.recognizeText(in: image)
                guard !text.isEmpty else {
                    popover.show(original: "", translated: "No text recognized.", canRetry: false)
                    return
                }
                let translated = try await translation.translate(
                    text: text,
                    targetLanguage: settings.targetLanguage,
                    config: .init(baseURL: settings.baseURL, apiKey: keychain.apiKey, model: settings.model)
                )
                popover.show(original: text, translated: translated, canRetry: false)
            } catch {
                popover.show(original: "", translated: error.localizedDescription, canRetry: true)
            }
        }
    }

    private func capture(region: CGRect, on screen: NSScreen) -> NSImage? {
        let globalRect = CGRect(
            x: screen.frame.minX + region.minX,
            y: screen.frame.minY + region.minY,
            width: region.width,
            height: region.height
        )
        guard let image = CGWindowListCreateImage(globalRect, .optionOnScreenOnly, kCGNullWindowID, [.bestResolution]) else {
            return nil
        }
        return NSImage(cgImage: image, size: globalRect.size)
    }
}
```

- [ ] **Step 3: Wire screenshot menu action**

In `AppShell`, add:

```swift
private let ocr = OCRService()
private lazy var screenCaptureTranslator = ScreenCaptureTranslator(
    settings: settings,
    keychain: keychain,
    ocr: ocr,
    translation: translation,
    popover: popover
)
```

Replace:

```swift
@objc private func screenshotTranslate() {}
```

with:

```swift
@objc private func screenshotTranslate() { screenCaptureTranslator.start() }
```

- [ ] **Step 4: Build**

Run: `swift build`

Expected: pass.

- [ ] **Step 5: Commit**

```bash
git add Sources/TextLens/AppShell.swift Sources/TextLens/ScreenCaptureTranslator.swift Sources/TextLens/RegionSelectionWindow.swift
git commit -m "feat: add screenshot translation flow"
```

## Task 9: Settings UI

**Files:**
- Create: `Sources/TextLens/SettingsView.swift`
- Modify: `Sources/TextLens/AppShell.swift`

- [ ] **Step 1: Implement settings window**

```swift
// Sources/TextLens/SettingsView.swift
import SwiftUI

struct SettingsView: View {
    @State private var baseURL: String
    @State private var model: String
    @State private var targetLanguage: String
    @State private var apiKey: String

    private let settings: SettingsStore
    private let keychain: KeychainStore

    init(settings: SettingsStore, keychain: KeychainStore) {
        self.settings = settings
        self.keychain = keychain
        _baseURL = State(initialValue: settings.baseURL.absoluteString)
        _model = State(initialValue: settings.model)
        _targetLanguage = State(initialValue: settings.targetLanguage)
        _apiKey = State(initialValue: keychain.apiKey)
    }

    var body: some View {
        Form {
            TextField("Base URL", text: $baseURL)
            SecureField("API Key", text: $apiKey)
            TextField("Model", text: $model)
            TextField("Target Language", text: $targetLanguage)
            Button("Save") { save() }
        }
        .padding()
        .frame(width: 460)
    }

    private func save() {
        if let url = URL(string: baseURL) {
            settings.baseURL = url
        }
        settings.model = model
        settings.targetLanguage = targetLanguage
        keychain.apiKey = apiKey
    }
}
```

- [ ] **Step 2: Wire settings menu**

In `AppShell`, add imports and property:

```swift
import SwiftUI

private var settingsWindow: NSWindow?
```

Replace `openSettings` with:

```swift
@objc private func openSettings() {
    let view = SettingsView(settings: settings, keychain: keychain)
    let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 460, height: 260), styleMask: [.titled, .closable], backing: .buffered, defer: false)
    window.title = "TextLens Settings"
    window.contentView = NSHostingView(rootView: view)
    window.center()
    window.makeKeyAndOrderFront(nil)
    settingsWindow = window
}
```

- [ ] **Step 3: Build**

Run: `swift build`

Expected: pass.

- [ ] **Step 4: Commit**

```bash
git add Sources/TextLens/AppShell.swift Sources/TextLens/SettingsView.swift
git commit -m "feat: add settings UI"
```

## Task 10: Manual Verification

**Files:**
- Modify only files needed for compile fixes.

- [ ] **Step 1: Run all automated tests**

Run: `swift test`

Expected: all tests pass.

- [ ] **Step 2: Build app**

Run: `swift build`

Expected: build succeeds.

- [ ] **Step 3: Launch app manually**

Run: `swift run TextLens`

Expected: menu bar item named `TextLens` appears.

- [ ] **Step 4: Verify flows**

Manual checklist:

- Open Settings and save Base URL, API Key, Model, and Target Language.
- Copy text, then run `Translate Clipboard`.
- Select text in TextEdit, then run `Translate Selection`.
- Run `Screenshot Translate` and grant Screen Recording if prompted.
- Confirm result window can copy translated text.
- Quit from the menu.

- [ ] **Step 5: Commit fixes**

```bash
git add .
git commit -m "fix: polish TextLens manual verification issues"
```

## Self-Review

- Spec coverage: selected-text translation, clipboard fallback, screenshot translation, local OCR, OpenAI-compatible API, Keychain, settings, popover, and tests are all mapped to tasks.
- Deferred scope remains deferred: no history, plugin system, automatic popup, offline models, or full multi-display drag selection.
- Known simplification: region selection is limited to the screen where the mouse starts. Full cross-display drag selection remains deferred by the spec.
