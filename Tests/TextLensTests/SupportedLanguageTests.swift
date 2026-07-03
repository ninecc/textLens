import XCTest
@testable import TextLensCore

final class SupportedLanguageTests: XCTestCase {
    func testUnitedNationsLanguages() {
        XCTAssertEqual(SupportedLanguage.unitedNations.map(\.name), [
            "Arabic",
            "Chinese",
            "English",
            "French",
            "Russian",
            "Spanish"
        ])
        XCTAssertEqual(SupportedLanguage.unitedNations.map(\.displayName), [
            "العربية",
            "中文",
            "English",
            "Français",
            "Русский",
            "Español"
        ])
    }

    func testNormalizesUnknownLanguageToChinese() {
        XCTAssertEqual(SupportedLanguage.normalized("Japanese").name, "Chinese")
    }
}
