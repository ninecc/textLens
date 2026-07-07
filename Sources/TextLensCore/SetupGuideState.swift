import Foundation

public struct SetupGuideState: Equatable {
    public let accessibility: PermissionState
    public let screenRecording: PermissionState
    public let skippedPermissions: Bool
    public let targetLanguage: String
    public let testedTranslationPath: Bool

    public init(
        accessibility: PermissionState,
        screenRecording: PermissionState,
        skippedPermissions: Bool,
        targetLanguage: String,
        testedTranslationPath: Bool
    ) {
        self.accessibility = accessibility
        self.screenRecording = screenRecording
        self.skippedPermissions = skippedPermissions
        self.targetLanguage = targetLanguage
        self.testedTranslationPath = testedTranslationPath
    }

    public var isComplete: Bool {
        let permissionsReady = skippedPermissions || (accessibility.isGranted && screenRecording.isGranted)
        return permissionsReady
            && !targetLanguage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && testedTranslationPath
    }
}
