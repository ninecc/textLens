import SwiftUI
import TextLensCore

struct SettingsView: View {
    @State private var baseURL: String
    @State private var model: String
    @State private var targetLanguage: String
    @State private var freeTranslationProvider: FreeTranslationProvider
    @State private var youdaoAppID: String
    @State private var youdaoSecret: String
    @State private var baiduAppID: String
    @State private var baiduSecret: String
    @State private var apiKey: String
    @State private var useAPIFallback: Bool
    @State private var screenshotPopoverOpacity: Double
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
        _freeTranslationProvider = State(initialValue: settings.freeTranslationProvider)
        _youdaoAppID = State(initialValue: settings.youdaoAppID)
        _youdaoSecret = State(initialValue: settings.youdaoSecret)
        _baiduAppID = State(initialValue: settings.baiduAppID)
        _baiduSecret = State(initialValue: settings.baiduSecret)
        _apiKey = State(initialValue: settings.apiKey)
        _useAPIFallback = State(initialValue: settings.useAPIFallback)
        _screenshotPopoverOpacity = State(initialValue: settings.screenshotPopoverOpacity)
    }

    var body: some View {
        Form {
            translationSection
            credentialsSection
            popoverSection
            apiFallbackSection
            actionsSection
        }
        .padding()
        .frame(width: 620)
        .onChange(of: baseURL) { _ in saved = false }
        .onChange(of: model) { _ in saved = false }
        .onChange(of: targetLanguage) { _ in saved = false }
        .onChange(of: freeTranslationProvider) { _ in saved = false }
        .onChange(of: youdaoAppID) { _ in saved = false }
        .onChange(of: youdaoSecret) { _ in saved = false }
        .onChange(of: baiduAppID) { _ in saved = false }
        .onChange(of: baiduSecret) { _ in saved = false }
        .onChange(of: apiKey) { _ in saved = false }
        .onChange(of: useAPIFallback) { _ in saved = false }
        .onChange(of: screenshotPopoverOpacity) { _ in saved = false }
    }

    private var translationSection: some View {
        Section("Translation") {
            Picker("Target Language", selection: $targetLanguage) {
                ForEach(SupportedLanguage.unitedNations) { language in
                    Text(language.displayName).tag(language.name)
                }
            }
            Picker("Free Provider", selection: $freeTranslationProvider) {
                ForEach(FreeTranslationProvider.allCases) { provider in
                    Text(provider.displayName).tag(provider)
                }
            }
        }
    }

    @ViewBuilder
    private var credentialsSection: some View {
        if freeTranslationProvider == .youdao {
            Section("Provider Credentials") {
                TextField("Youdao App ID", text: $youdaoAppID)
                SecureField("Youdao Secret", text: $youdaoSecret)
            }
        }

        if freeTranslationProvider == .baidu {
            Section("Provider Credentials") {
                TextField("Baidu App ID", text: $baiduAppID)
                SecureField("Baidu Secret", text: $baiduSecret)
            }
        }
    }

    private var popoverSection: some View {
        Section("Popover") {
            Stepper(value: $screenshotPopoverOpacity, in: 0.1...1.0, step: 0.1) {
                HStack {
                    Text("Screenshot opacity")
                    TextField("Opacity", value: $screenshotPopoverOpacity, format: .number.precision(.fractionLength(1)))
                        .frame(width: 72)
                        .onSubmit { screenshotPopoverOpacity = clampedOpacity(screenshotPopoverOpacity) }
                    Text("0.1-1.0")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var apiFallbackSection: some View {
        Section("API Fallback") {
            Toggle("Use API fallback", isOn: $useAPIFallback)
            TextField("Base URL", text: $baseURL)
            SecureField("API Key", text: $apiKey)
            TextField("Model", text: $model)
            HStack {
                Button(testingAPI ? "Testing..." : "Test API") { testAPI() }
                    .disabled(testingAPI)
                Text(apiStatus)
            }
        }
    }

    private var actionsSection: some View {
        HStack {
            Button(saved ? "Saved" : "Save") { save() }
            Button("Restore Defaults") { restoreDefaults() }
        }
    }

    private func save() {
        saved = saveModel.save(
            SettingsDraft(
                baseURL: baseURL,
                model: model,
                targetLanguage: targetLanguage,
                freeTranslationProvider: freeTranslationProvider,
                youdaoAppID: youdaoAppID,
                youdaoSecret: youdaoSecret,
                baiduAppID: baiduAppID,
                baiduSecret: baiduSecret,
                apiKey: apiKey,
                useAPIFallback: useAPIFallback,
                screenshotPopoverOpacity: screenshotPopoverOpacity
            )
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
        freeTranslationProvider = settings.freeTranslationProvider
        youdaoAppID = settings.youdaoAppID
        youdaoSecret = settings.youdaoSecret
        baiduAppID = settings.baiduAppID
        baiduSecret = settings.baiduSecret
        apiKey = settings.apiKey
        useAPIFallback = settings.useAPIFallback
        screenshotPopoverOpacity = settings.screenshotPopoverOpacity
        apiStatus = ""
        saved = false
    }

    private func clampedOpacity(_ value: Double) -> Double {
        min(max((value * 10).rounded() / 10, 0.1), 1.0)
    }
}
