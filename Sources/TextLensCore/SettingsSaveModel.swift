import Foundation

public struct SettingsDraft {
    public let baseURL: String
    public let model: String
    public let targetLanguage: String
    public let apiKey: String
    public let useAPIFallback: Bool

    public init(baseURL: String, model: String, targetLanguage: String, apiKey: String, useAPIFallback: Bool) {
        self.baseURL = baseURL
        self.model = model
        self.targetLanguage = targetLanguage
        self.apiKey = apiKey
        self.useAPIFallback = useAPIFallback
    }
}

public final class SettingsSaveModel {
    private let settings: SettingsStore

    public init(settings: SettingsStore) {
        self.settings = settings
    }

    @discardableResult
    public func save(_ draft: SettingsDraft) -> Bool {
        if let url = URL(string: draft.baseURL) {
            settings.baseURL = url
        }
        settings.model = draft.model
        settings.targetLanguage = draft.targetLanguage
        settings.apiKey = draft.apiKey
        settings.useAPIFallback = draft.useAPIFallback
        return true
    }
}
