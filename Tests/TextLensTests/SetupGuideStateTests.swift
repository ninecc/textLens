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
            testedTranslationPath: true
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
