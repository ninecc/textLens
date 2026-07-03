import XCTest
@testable import TextLensCore

final class SettingsStoreTests: XCTestCase {
    func testDefaults() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let store = SettingsStore(defaults: defaults)

        XCTAssertEqual(store.baseURL, URL(string: "https://api.openai.com/v1/chat/completions")!)
        XCTAssertEqual(store.model, "gpt-4o-mini")
        XCTAssertEqual(store.targetLanguage, "Chinese")
        XCTAssertEqual(store.freeTranslationProvider, .google)
        XCTAssertEqual(store.youdaoAppID, "")
        XCTAssertEqual(store.youdaoSecret, "")
        XCTAssertEqual(store.baiduAppID, "")
        XCTAssertEqual(store.baiduSecret, "")
        XCTAssertEqual(store.apiKey, "")
        XCTAssertFalse(store.useAPIFallback)
        XCTAssertEqual(store.screenshotPopoverOpacity, 0.9)
    }

    func testReadWrite() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let store = SettingsStore(defaults: defaults)

        store.baseURL = URL(string: "https://example.com/v1/chat/completions")!
        store.model = "test-model"
        store.targetLanguage = "Russian"
        store.freeTranslationProvider = .baidu
        store.youdaoAppID = "youdao-app"
        store.youdaoSecret = "youdao-secret"
        store.baiduAppID = "baidu-app"
        store.baiduSecret = "baidu-secret"
        store.apiKey = "test-key"
        store.useAPIFallback = true
        store.screenshotPopoverOpacity = 0.4

        XCTAssertEqual(store.baseURL.absoluteString, "https://example.com/v1/chat/completions")
        XCTAssertEqual(store.model, "test-model")
        XCTAssertEqual(store.targetLanguage, "Russian")
        XCTAssertEqual(store.freeTranslationProvider, .baidu)
        XCTAssertEqual(store.youdaoAppID, "youdao-app")
        XCTAssertEqual(store.youdaoSecret, "youdao-secret")
        XCTAssertEqual(store.baiduAppID, "baidu-app")
        XCTAssertEqual(store.baiduSecret, "baidu-secret")
        XCTAssertEqual(store.apiKey, "test-key")
        XCTAssertTrue(store.useAPIFallback)
        XCTAssertEqual(store.screenshotPopoverOpacity, 0.4)
    }

    func testScreenshotPopoverOpacityIsClamped() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let store = SettingsStore(defaults: defaults)

        store.screenshotPopoverOpacity = -1
        XCTAssertEqual(store.screenshotPopoverOpacity, 0.1)

        store.screenshotPopoverOpacity = 2
        XCTAssertEqual(store.screenshotPopoverOpacity, 1.0)
    }

    func testResetToDefaults() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let store = SettingsStore(defaults: defaults)

        store.baseURL = URL(string: "https://example.com/v1/chat/completions")!
        store.model = "test-model"
        store.targetLanguage = "Russian"
        store.freeTranslationProvider = .baidu
        store.youdaoAppID = "youdao-app"
        store.youdaoSecret = "youdao-secret"
        store.baiduAppID = "baidu-app"
        store.baiduSecret = "baidu-secret"
        store.apiKey = "test-key"
        store.useAPIFallback = true
        store.screenshotPopoverOpacity = 0.4

        store.resetToDefaults()

        XCTAssertEqual(store.baseURL, URL(string: "https://api.openai.com/v1/chat/completions")!)
        XCTAssertEqual(store.model, "gpt-4o-mini")
        XCTAssertEqual(store.targetLanguage, "Chinese")
        XCTAssertEqual(store.freeTranslationProvider, .google)
        XCTAssertEqual(store.youdaoAppID, "")
        XCTAssertEqual(store.youdaoSecret, "")
        XCTAssertEqual(store.baiduAppID, "")
        XCTAssertEqual(store.baiduSecret, "")
        XCTAssertEqual(store.apiKey, "")
        XCTAssertFalse(store.useAPIFallback)
        XCTAssertEqual(store.screenshotPopoverOpacity, 0.9)
    }
}
