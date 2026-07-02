import XCTest
@testable import TextLensCore

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
