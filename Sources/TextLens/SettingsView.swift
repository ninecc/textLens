import SwiftUI
import TextLensCore

struct SettingsView: View {
    @State private var baseURL: String
    @State private var model: String
    @State private var targetLanguage: String
    @State private var apiKey: String
    @State private var useAPIFallback: Bool
    @State private var saved = false
    @State private var apiStatus = ""
    @State private var testingAPI = false

    private let settings: SettingsStore
    private let saveModel: SettingsSaveModel
    private let translation = TranslationService()

    init(settings: SettingsStore) {
        self.settings = settings
        saveModel = SettingsSaveModel(settings: settings)
        _baseURL = State(initialValue: settings.baseURL.absoluteString)
        _model = State(initialValue: settings.model)
        _targetLanguage = State(initialValue: settings.targetLanguage)
        _apiKey = State(initialValue: settings.apiKey)
        _useAPIFallback = State(initialValue: settings.useAPIFallback)
    }

    var body: some View {
        Form {
            Picker("Target Language", selection: $targetLanguage) {
                ForEach(SupportedLanguage.unitedNations) { language in
                    Text(language.displayName).tag(language.name)
                }
            }
            TextField("Base URL", text: $baseURL)
            SecureField("API Key", text: $apiKey)
            TextField("Model", text: $model)
            Toggle("Use API fallback", isOn: $useAPIFallback)
            Button(saved ? "Saved" : "Save") { save() }
            HStack {
                Button(testingAPI ? "Testing..." : "Test API") { testAPI() }
                    .disabled(testingAPI)
                Text(apiStatus)
            }
            Button("Restore Defaults") { restoreDefaults() }
        }
        .padding()
        .frame(width: 460)
        .onChange(of: baseURL) { _ in saved = false }
        .onChange(of: model) { _ in saved = false }
        .onChange(of: targetLanguage) { _ in saved = false }
        .onChange(of: apiKey) { _ in saved = false }
        .onChange(of: useAPIFallback) { _ in saved = false }
    }

    private func save() {
        saved = saveModel.save(
            SettingsDraft(baseURL: baseURL, model: model, targetLanguage: targetLanguage, apiKey: apiKey, useAPIFallback: useAPIFallback)
        )
    }

    private func testAPI() {
        guard let url = URL(string: baseURL), !apiKey.isEmpty else {
            apiStatus = "Missing API settings."
            return
        }
        testingAPI = true
        apiStatus = ""
        Task {
            do {
                _ = try await translation.translate(text: "hello", targetLanguage: targetLanguage, config: .init(baseURL: url, apiKey: apiKey, model: model))
                await MainActor.run { apiStatus = "API available." }
            } catch {
                await MainActor.run { apiStatus = error.localizedDescription }
            }
            await MainActor.run { testingAPI = false }
        }
    }

    private func restoreDefaults() {
        settings.resetToDefaults()
        baseURL = settings.baseURL.absoluteString
        model = settings.model
        targetLanguage = settings.targetLanguage
        apiKey = settings.apiKey
        useAPIFallback = settings.useAPIFallback
        apiStatus = ""
        saved = false
    }
}
