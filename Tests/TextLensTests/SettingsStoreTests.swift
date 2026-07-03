import XCTest
@testable import TextLensCore

final class SettingsStoreTests: XCTestCase {
    func testDefaults() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let store = SettingsStore(defaults: defaults)

        XCTAssertEqual(store.baseURL, URL(string: "https://api.openai.com/v1/chat/completions")!)
        XCTAssertEqual(store.model, "gpt-4o-mini")
        XCTAssertEqual(store.targetLanguage, "Chinese")
        XCTAssertEqual(store.apiKey, "")
        XCTAssertFalse(store.useAPIFallback)
    }

    func testReadWrite() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let store = SettingsStore(defaults: defaults)

        store.baseURL = URL(string: "https://example.com/v1/chat/completions")!
        store.model = "test-model"
        store.targetLanguage = "Russian"
        store.apiKey = "test-key"
        store.useAPIFallback = true

        XCTAssertEqual(store.baseURL.absoluteString, "https://example.com/v1/chat/completions")
        XCTAssertEqual(store.model, "test-model")
        XCTAssertEqual(store.targetLanguage, "Russian")
        XCTAssertEqual(store.apiKey, "test-key")
        XCTAssertTrue(store.useAPIFallback)
    }

    func testResetToDefaults() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let store = SettingsStore(defaults: defaults)

        store.baseURL = URL(string: "https://example.com/v1/chat/completions")!
        store.model = "test-model"
        store.targetLanguage = "Russian"
        store.apiKey = "test-key"
        store.useAPIFallback = true

        store.resetToDefaults()

        XCTAssertEqual(store.baseURL, URL(string: "https://api.openai.com/v1/chat/completions")!)
        XCTAssertEqual(store.model, "gpt-4o-mini")
        XCTAssertEqual(store.targetLanguage, "Chinese")
        XCTAssertEqual(store.apiKey, "")
        XCTAssertFalse(store.useAPIFallback)
    }
}
