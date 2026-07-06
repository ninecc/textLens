import Foundation
import TextLensCore

final class TranslationRunner {
    enum Error: LocalizedError {
        case freeTranslationFailed(String)

        var errorDescription: String? {
            switch self {
            case .freeTranslationFailed(let message):
                return "Free translation failed: \(message). Add an API key and enable API translation to use fallback."
            }
        }
    }

    private let settings: SettingsStore
    private let api: TranslationService
    private let free = FreeTranslationService()

    init(settings: SettingsStore, api: TranslationService) {
        self.settings = settings
        self.api = api
    }

    func translate(_ text: String) async throws -> String {
        var freeError: Swift.Error?
        for config in freeConfigs() {
            do {
                let translated = try await free.translate(text: text, targetLanguage: settings.targetLanguage, config: config)
                return finish(translated, provider: config.provider.displayName)
            } catch {
                freeError = error
                settings.providerHealth = "\(config.provider.displayName) failed: \(error.localizedDescription)"
            }
        }

        guard settings.useAPIFallback else {
            throw Error.freeTranslationFailed(freeError?.localizedDescription ?? "No free provider was available.")
        }
        let apiKey = settings.apiKey
        guard !apiKey.isEmpty else {
            throw Error.freeTranslationFailed("API fallback needs an API key. Open Settings and enter one.")
        }

        let translated = try await api.translate(
            text: text,
            targetLanguage: settings.targetLanguage,
            config: .init(baseURL: settings.baseURL, apiKey: apiKey, model: settings.model)
        )
        return finish(translated, provider: "API fallback")
    }

    private func freeConfigs() -> [FreeTranslationService.Config] {
        let selected = config(for: settings.freeTranslationProvider)

        let backupProviders: [FreeTranslationProvider] = [.google, .myMemory]
            .filter { $0 != settings.freeTranslationProvider }

        return [selected] + backupProviders.map { .init(provider: $0) }
    }

    private func config(for provider: FreeTranslationProvider) -> FreeTranslationService.Config {
        switch provider {
        case .youdao:
            return .init(provider: provider, youdaoAppID: settings.youdaoAppID, youdaoSecret: settings.youdaoSecret)
        case .baidu:
            return .init(provider: provider, baiduAppID: settings.baiduAppID, baiduSecret: settings.baiduSecret)
        case .google, .myMemory:
            return .init(provider: provider)
        }
    }

    private func finish(_ translated: String, provider: String) -> String {
        settings.providerHealth = "Last success: \(provider)"
        return Glossary(text: settings.glossaryText).apply(to: translated)
    }
}
