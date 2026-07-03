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
    private let free = GoogleTranslationService()

    init(settings: SettingsStore, api: TranslationService) {
        self.settings = settings
        self.api = api
    }

    func translate(_ text: String) async throws -> String {
        do {
            return try await free.translate(text: text, targetLanguage: settings.targetLanguage)
        } catch {
            guard settings.useAPIFallback, !settings.apiKey.isEmpty else {
                throw Error.freeTranslationFailed(error.localizedDescription)
            }
            return try await api.translate(
                text: text,
                targetLanguage: settings.targetLanguage,
                config: .init(baseURL: settings.baseURL, apiKey: settings.apiKey, model: settings.model)
            )
        }
    }
}
