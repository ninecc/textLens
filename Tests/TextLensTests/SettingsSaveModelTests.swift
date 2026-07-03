import XCTest
@testable import TextLensCore

final class SettingsSaveModelTests: XCTestCase {
    func testSaveDoesNotWaitForAPIKeyStorage() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let store = SettingsStore(defaults: defaults)
        let model = SettingsSaveModel(settings: store)
        let started = DispatchSemaphore(value: 0)
        let release = DispatchSemaphore(value: 0)

        let start = Date()
        let result = model.save(
            SettingsDraft(
                baseURL: "https://example.com/v1/chat/completions",
                model: "model",
                targetLanguage: "Japanese",
                apiKey: "key"
            ),
            saveAPIKey: { _ in
                started.signal()
                release.wait()
            }
        )

        XCTAssertLessThan(Date().timeIntervalSince(start), 0.2)
        XCTAssertTrue(result)
        XCTAssertEqual(started.wait(timeout: .now() + 1), .success)
        XCTAssertEqual(store.baseURL.absoluteString, "https://example.com/v1/chat/completions")
        XCTAssertEqual(store.model, "model")
        XCTAssertEqual(store.targetLanguage, "Japanese")
        release.signal()
    }
}
