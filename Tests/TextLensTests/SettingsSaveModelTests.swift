import XCTest
@testable import TextLensCore

final class SettingsSaveModelTests: XCTestCase {
    func testSaveWritesSettings() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let store = SettingsStore(defaults: defaults)
        let model = SettingsSaveModel(settings: store)

        let result = model.save(
            SettingsDraft(
                baseURL: "https://example.com/v1/chat/completions",
                model: "model",
                targetLanguage: "French",
                apiKey: "key",
                useAPIFallback: false
            )
        )

        XCTAssertTrue(result)
        XCTAssertEqual(store.baseURL.absoluteString, "https://example.com/v1/chat/completions")
        XCTAssertEqual(store.model, "model")
        XCTAssertEqual(store.targetLanguage, "French")
        XCTAssertEqual(store.apiKey, "key")
        XCTAssertFalse(store.useAPIFallback)
    }
}
