import SwiftUI
import TextLensCore

struct SettingsView: View {
    private enum Pane: String, CaseIterable, Identifiable {
        case translation = "Translation"
        case popover = "Popover"
        case api = "API"

        var id: Self { self }
    }

    @State private var selectedPane: Pane = .translation
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
        HStack(spacing: 0) {
            List(Pane.allCases, selection: $selectedPane) { pane in
                Text(pane.rawValue)
                    .tag(pane)
                    .padding(.vertical, 4)
            }
            .listStyle(.sidebar)
            .frame(width: 180)

            Divider()

            VStack(alignment: .leading, spacing: 0) {
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                Divider()

                actionsSection
                    .padding(.top, 16)
            }
            .padding(24)
        }
        .frame(width: 820, height: 520)
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

    @ViewBuilder
    private var content: some View {
        switch selectedPane {
        case .translation:
            page("Translation") {
                formRow("Target Language") {
                    Picker("", selection: $targetLanguage) {
                        ForEach(SupportedLanguage.unitedNations) { language in
                            Text(language.displayName).tag(language.name)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 220)
                }

                formRow("Free Provider") {
                    Picker("", selection: $freeTranslationProvider) {
                        ForEach(FreeTranslationProvider.allCases) { provider in
                            Text(provider.displayName).tag(provider)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 220)
                }

                credentialsSection
            }
        case .popover:
            page("Popover") {
                formRow("Screenshot opacity") {
                    HStack(spacing: 10) {
                        TextField("Opacity", value: $screenshotPopoverOpacity, format: .number.precision(.fractionLength(1)))
                            .frame(width: 72)
                            .onSubmit { screenshotPopoverOpacity = clampedOpacity(screenshotPopoverOpacity) }
                        Stepper("", value: $screenshotPopoverOpacity, in: 0.1...1.0, step: 0.1)
                            .labelsHidden()
                        Text("0.1-1.0")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        case .api:
            page("API") {
                formRow("Use API fallback") {
                    Toggle("", isOn: $useAPIFallback)
                        .labelsHidden()
                }
                formRow("Base URL") {
                    TextField("Base URL", text: $baseURL)
                        .textFieldStyle(.roundedBorder)
                }
                formRow("API Key") {
                    SecureField("API Key", text: $apiKey)
                        .textFieldStyle(.roundedBorder)
                }
                formRow("Model") {
                    TextField("Model", text: $model)
                        .textFieldStyle(.roundedBorder)
                }
                HStack(spacing: 12) {
                    Spacer()
                        .frame(width: 150)
                    Button(testingAPI ? "Testing..." : "Test API") { testAPI() }
                        .disabled(testingAPI)
                    Text(apiStatus)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
    }

    @ViewBuilder
    private var credentialsSection: some View {
        if freeTranslationProvider == .baidu {
            Divider()
                .padding(.vertical, 8)
            Text("Provider Credentials")
                .font(.headline)
            formRow("Baidu App ID") {
                TextField("Baidu App ID", text: $baiduAppID)
                    .textFieldStyle(.roundedBorder)
            }
            formRow("Baidu Secret") {
                SecureField("Baidu Secret", text: $baiduSecret)
                    .textFieldStyle(.roundedBorder)
            }
        } else if freeTranslationProvider == .youdao {
            Divider()
                .padding(.vertical, 8)
            Text("Provider Credentials")
                .font(.headline)
            formRow("Youdao App ID") {
                TextField("Youdao App ID", text: $youdaoAppID)
                    .textFieldStyle(.roundedBorder)
            }
            formRow("Youdao Secret") {
                SecureField("Youdao Secret", text: $youdaoSecret)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    private func page<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title2.bold())
                .padding(.bottom, 8)
            content()
        }
    }

    private func formRow<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .center, spacing: 16) {
            Text(title)
                .frame(width: 150, alignment: .trailing)
                .foregroundStyle(.secondary)
            content()
                .frame(maxWidth: 420, alignment: .leading)
        }
    }

    private var actionsSection: some View {
        HStack {
            Spacer()
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
