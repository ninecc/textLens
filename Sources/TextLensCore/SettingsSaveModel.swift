import Foundation

public struct SettingsDraft {
    public let baseURL: String
    public let model: String
    public let targetLanguage: String
    public let freeTranslationProvider: FreeTranslationProvider
    public let youdaoAppID: String
    public let youdaoSecret: String
    public let baiduAppID: String
    public let baiduSecret: String
    public let apiKey: String
    public let useAPIFallback: Bool

    public init(
        baseURL: String,
        model: String,
        targetLanguage: String,
        freeTranslationProvider: FreeTranslationProvider,
        youdaoAppID: String,
        youdaoSecret: String,
        baiduAppID: String,
        baiduSecret: String,
        apiKey: String,
        useAPIFallback: Bool
    ) {
        self.baseURL = baseURL
        self.model = model
        self.targetLanguage = targetLanguage
        self.freeTranslationProvider = freeTranslationProvider
        self.youdaoAppID = youdaoAppID
        self.youdaoSecret = youdaoSecret
        self.baiduAppID = baiduAppID
        self.baiduSecret = baiduSecret
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
        settings.freeTranslationProvider = draft.freeTranslationProvider
        settings.youdaoAppID = draft.youdaoAppID
        settings.youdaoSecret = draft.youdaoSecret
        settings.baiduAppID = draft.baiduAppID
        settings.baiduSecret = draft.baiduSecret
        settings.apiKey = draft.apiKey
        settings.useAPIFallback = draft.useAPIFallback
        return true
    }
}
