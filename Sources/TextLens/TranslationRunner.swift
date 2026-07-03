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
                return try await free.translate(text: text, targetLanguage: settings.targetLanguage, config: config)
            } catch {
                freeError = error
            }
        }

        guard settings.useAPIFallback, !settings.apiKey.isEmpty else {
            throw Error.freeTranslationFailed(freeError?.localizedDescription ?? "No free provider was available.")
        }

        return try await api.translate(
            text: text,
            targetLanguage: settings.targetLanguage,
            config: .init(baseURL: settings.baseURL, apiKey: settings.apiKey, model: settings.model)
        )
    }

    private func freeConfigs() -> [FreeTranslationService.Config] {
        let selected = FreeTranslationService.Config(
            provider: settings.freeTranslationProvider,
            youdaoAppID: settings.youdaoAppID,
            youdaoSecret: settings.youdaoSecret,
            baiduAppID: settings.baiduAppID,
            baiduSecret: settings.baiduSecret
        )

        let backupProviders: [FreeTranslationProvider] = [.google, .myMemory]
            .filter { $0 != settings.freeTranslationProvider }

        return [selected] + backupProviders.map { .init(provider: $0) }
    }
}
