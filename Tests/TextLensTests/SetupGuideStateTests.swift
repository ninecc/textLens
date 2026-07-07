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
