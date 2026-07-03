import Foundation

public final class SettingsStore {
    private enum Key {
        static let baseURL = "baseURL"
        static let model = "model"
        static let targetLanguage = "targetLanguage"
        static let apiKey = "apiKey"
        static let useAPIFallback = "useAPIFallback"
    }

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public var baseURL: URL {
        get {
            if let value = defaults.string(forKey: Key.baseURL), let url = URL(string: value) {
                return url
            }
            return URL(string: "https://api.openai.com/v1/chat/completions")!
        }
        set { defaults.set(newValue.absoluteString, forKey: Key.baseURL) }
    }

    public var model: String {
        get { defaults.string(forKey: Key.model) ?? "gpt-4o-mini" }
        set { defaults.set(newValue, forKey: Key.model) }
    }

    public var targetLanguage: String {
        get { defaults.string(forKey: Key.targetLanguage) ?? "Chinese" }
        set { defaults.set(SupportedLanguage.normalized(newValue).name, forKey: Key.targetLanguage) }
    }

    public var apiKey: String {
        get { defaults.string(forKey: Key.apiKey) ?? "" }
        set { defaults.set(newValue, forKey: Key.apiKey) }
    }

    public var useAPIFallback: Bool {
        get {
            defaults.object(forKey: Key.useAPIFallback) as? Bool ?? false
        }
        set { defaults.set(newValue, forKey: Key.useAPIFallback) }
    }

    public func resetToDefaults() {
        defaults.removeObject(forKey: Key.baseURL)
        defaults.removeObject(forKey: Key.model)
        defaults.removeObject(forKey: Key.targetLanguage)
        defaults.removeObject(forKey: Key.apiKey)
        defaults.removeObject(forKey: Key.useAPIFallback)
    }
}
