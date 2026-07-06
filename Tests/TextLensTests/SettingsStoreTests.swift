import XCTest
@testable import TextLensCore

final class SettingsStoreTests: XCTestCase {
    func testDefaults() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let store = SettingsStore(defaults: defaults, secrets: InMemorySecretStore())

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
        XCTAssertFalse(store.hasSeenOnboarding)
    }

    func testReadWrite() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let store = SettingsStore(defaults: defaults, secrets: InMemorySecretStore())

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
        store.hasSeenOnboarding = true

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
        XCTAssertTrue(store.hasSeenOnboarding)
    }

    func testSecretsAreStoredOutsideUserDefaults() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let secrets = InMemorySecretStore()
        let store = SettingsStore(defaults: defaults, secrets: secrets)

        store.apiKey = "api-secret"
        store.youdaoSecret = "youdao-secret"
        store.baiduSecret = "baidu-secret"

        XCTAssertEqual(secrets.values["apiKey"], "api-secret")
        XCTAssertEqual(secrets.values["youdaoSecret"], "youdao-secret")
        XCTAssertEqual(secrets.values["baiduSecret"], "baidu-secret")
        XCTAssertNil(defaults.string(forKey: "apiKey"))
        XCTAssertNil(defaults.string(forKey: "youdaoSecret"))
        XCTAssertNil(defaults.string(forKey: "baiduSecret"))
    }

    func testReadsAndMigratesExistingUserDefaultsSecret() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        defaults.set("old-secret", forKey: "apiKey")
        let secrets = InMemorySecretStore()
        let store = SettingsStore(defaults: defaults, secrets: secrets)

        XCTAssertEqual(store.apiKey, "old-secret")
        XCTAssertEqual(secrets.values["apiKey"], "old-secret")
        XCTAssertNil(defaults.string(forKey: "apiKey"))
    }

    func testResetClearsSecrets() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let secrets = InMemorySecretStore()
        let store = SettingsStore(defaults: defaults, secrets: secrets)

        store.apiKey = "api-secret"
        store.youdaoSecret = "youdao-secret"
        store.baiduSecret = "baidu-secret"
        store.resetToDefaults()

        XCTAssertEqual(store.apiKey, "")
        XCTAssertEqual(store.youdaoSecret, "")
        XCTAssertEqual(store.baiduSecret, "")
        XCTAssertTrue(secrets.values.isEmpty)
    }

    func testScreenshotPopoverOpacityIsClamped() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let store = SettingsStore(defaults: defaults, secrets: InMemorySecretStore())

        store.screenshotPopoverOpacity = -1
        XCTAssertEqual(store.screenshotPopoverOpacity, 0.1)

        store.screenshotPopoverOpacity = 2
        XCTAssertEqual(store.screenshotPopoverOpacity, 1.0)
    }

    func testResetToDefaults() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let store = SettingsStore(defaults: defaults, secrets: InMemorySecretStore())

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
        store.hasSeenOnboarding = true

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
        XCTAssertFalse(store.hasSeenOnboarding)
    }
}
