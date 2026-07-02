import SwiftUI
import TextLensCore

struct SettingsView: View {
    @State private var baseURL: String
    @State private var model: String
    @State private var targetLanguage: String
    @State private var apiKey: String

    private let settings: SettingsStore
    private let keychain: KeychainStore

    init(settings: SettingsStore, keychain: KeychainStore) {
        self.settings = settings
        self.keychain = keychain
        _baseURL = State(initialValue: settings.baseURL.absoluteString)
        _model = State(initialValue: settings.model)
        _targetLanguage = State(initialValue: settings.targetLanguage)
        _apiKey = State(initialValue: keychain.apiKey)
    }

    var body: some View {
        Form {
            TextField("Base URL", text: $baseURL)
            SecureField("API Key", text: $apiKey)
            TextField("Model", text: $model)
            TextField("Target Language", text: $targetLanguage)
            Button("Save") { save() }
        }
        .padding()
        .frame(width: 460)
    }

    private func save() {
        if let url = URL(string: baseURL) {
            settings.baseURL = url
        }
        settings.model = model
        settings.targetLanguage = targetLanguage
        keychain.apiKey = apiKey
    }
}
