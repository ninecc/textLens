import AppKit
import SwiftUI
import TextLensCore

struct SettingsView: View {
    private enum Pane: String, CaseIterable, Identifiable {
        case translation = "Translation"
        case permissions = "Permissions"
        case popover = "Popover"
        case shortcuts = "Shortcuts"
        case history = "History"
        case glossary = "Glossary"
        case api = "API Fallback"

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
    @State private var selectionHotKey: String
    @State private var screenshotHotKey: String
    @State private var historyEnabled: Bool
    @State private var historyItems: [TranslationHistoryItem]
    @State private var historySearch = ""
    @State private var showingFavoritesOnly = false
    @State private var glossaryText: String
    @State private var exportStatus = ""
    @State private var saved = false
    @State private var apiStatus = ""
    @State private var testingAPI = false
    @State private var freeProviderStatus = ""
    @State private var testingFreeProvider = false
    @State private var comparisonStatus = ""
    @State private var testingComparison = false

    private let settings: SettingsStore
    private let historyStore: TranslationHistoryStore
    private let onShortcutsChanged: () -> Void
    private let saveModel: SettingsSaveModel
    private let translation = TranslationService()
    private let freeTranslation = FreeTranslationService()
    private let permissionCenter = PermissionCenter()

    init(settings: SettingsStore, historyStore: TranslationHistoryStore = TranslationHistoryStore(), onShortcutsChanged: @escaping () -> Void = {}) {
        self.settings = settings
        self.historyStore = historyStore
        self.onShortcutsChanged = onShortcutsChanged
        saveModel = SettingsSaveModel(settings: settings)
        _baseURL = State(initialValue: settings.baseURL.absoluteString)
        _model = State(initialValue: settings.model)
        _targetLanguage = State(initialValue: settings.targetLanguage)
        _freeTranslationProvider = State(initialValue: settings.freeTranslationProvider)
        _youdaoAppID = State(initialValue: settings.youdaoAppID)
        _youdaoSecret = State(initialValue: "")
        _baiduAppID = State(initialValue: settings.baiduAppID)
        _baiduSecret = State(initialValue: "")
        _apiKey = State(initialValue: "")
        _useAPIFallback = State(initialValue: settings.useAPIFallback)
        _screenshotPopoverOpacity = State(initialValue: settings.screenshotPopoverOpacity)
        _selectionHotKey = State(initialValue: settings.selectionHotKey)
        _screenshotHotKey = State(initialValue: settings.screenshotHotKey)
        _historyEnabled = State(initialValue: historyStore.isEnabled)
        _historyItems = State(initialValue: historyStore.items)
        _glossaryText = State(initialValue: settings.glossaryText)
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
        .frame(width: 880, height: 620)
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
        .onChange(of: selectionHotKey) { _ in saved = false }
        .onChange(of: screenshotHotKey) { _ in saved = false }
        .onChange(of: historyEnabled) { _ in saved = false }
        .onChange(of: glossaryText) { _ in saved = false }
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

                formRow("Active Strategy") {
                    Text(strategySummary)
                        .foregroundStyle(.secondary)
                }

                formRow("Fallback Order") {
                    Text(fallbackOrder)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                formRow("Provider Health") {
                    Text(settings.providerHealth)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                HStack(spacing: 12) {
                    Spacer()
                        .frame(width: 150)
                    Button(testingFreeProvider ? "Testing..." : "Test Free Provider") { testFreeProvider() }
                        .disabled(testingFreeProvider)
                    Button(testingComparison ? "Comparing..." : "Compare Providers") { compareProviders() }
                        .disabled(testingComparison)
                    Text(freeProviderStatus)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                formRow("Comparison") {
                    Text(comparisonStatus.isEmpty ? "No comparison yet." : comparisonStatus)
                        .foregroundStyle(.secondary)
                        .lineLimit(4)
                }

                credentialsSection
            }
        case .permissions:
            page("Permissions") {
                permissionRow(
                    "Accessibility",
                    state: permissionCenter.accessibility,
                    actionTitle: "Open Accessibility"
                ) {
                    permissionCenter.openAccessibilitySettings()
                }

                permissionRow(
                    "Screen Recording",
                    state: permissionCenter.screenRecording,
                    actionTitle: "Open Screen Recording"
                ) {
                    permissionCenter.openScreenRecordingSettings()
                }
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
        case .shortcuts:
            page("Shortcuts") {
                shortcutRow("Translate Selection", selection: $selectionHotKey)
                shortcutRow("Screenshot Translate", selection: $screenshotHotKey)
                formRow("Status") {
                    Text("Uses Control + Option + Command plus the selected key. If macOS refuses a shortcut, choose another key.")
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
            }
        case .history:
            page("History") {
                Toggle("Save translation history", isOn: $historyEnabled)
                HStack {
                    TextField("Search history", text: $historySearch)
                        .textFieldStyle(.roundedBorder)
                    Toggle("Favorites", isOn: $showingFavoritesOnly)
                        .toggleStyle(.checkbox)
                }
                .frame(maxWidth: 520)

                if visibleHistoryItems.isEmpty {
                    Text(historySearch.isEmpty ? "No history yet." : "No matching history.")
                        .foregroundStyle(.secondary)
                } else {
                    List(visibleHistoryItems) { item in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(item.original)
                                .font(.headline)
                                .lineLimit(2)
                            Text(item.translated)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                            HStack {
                                Button(item.isFavorite ? "Unfavorite" : "Favorite") {
                                    _ = historyStore.toggleFavorite(id: item.id)
                                    historyItems = historyStore.items
                                }
                                Button("Copy Translation") {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(item.translated, forType: .string)
                                }
                            }
                        }
                    }
                    .frame(height: 260)
                }

                HStack(spacing: 12) {
                    Button("Clear History") { clearHistory() }
                    Button("Export All") { exportHistory(favoritesOnly: false) }
                    Button("Export Favorites") { exportHistory(favoritesOnly: true) }
                        .disabled(!historyStore.items.contains { $0.isFavorite })
                    Text(exportStatus)
                        .foregroundStyle(.secondary)
                }
            }
        case .glossary:
            page("Glossary") {
                formRow("Entries") {
                    Text("One entry per line: source=preferred translation")
                        .foregroundStyle(.secondary)
                }
                TextEditor(text: $glossaryText)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 320)
                    .border(Color.secondary.opacity(0.25))
            }
        case .api:
            page("API Fallback") {
                formRow("Use API when free translation fails") {
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
                formRow("Keychain Access") {
                    Text("Leave blank to keep the saved key. macOS may ask for Keychain access when API fallback is used.")
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
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
            formRow("Keychain Access") {
                Text("Leave blank to keep the saved secret. macOS may ask for Keychain access when Baidu is used.")
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
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
            formRow("Keychain Access") {
                Text("Leave blank to keep the saved secret. macOS may ask for Keychain access when Youdao is used.")
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
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

    private func permissionRow(_ title: String, state: PermissionState, actionTitle: String, action: @escaping () -> Void) -> some View {
        formRow(title) {
            HStack(spacing: 12) {
                Text(state.displayName)
                    .foregroundStyle(state.isGranted ? .green : .secondary)
                    .frame(width: 72, alignment: .leading)
                Button(actionTitle, action: action)
            }
        }
    }

    private func shortcutRow(_ title: String, selection: Binding<String>) -> some View {
        formRow(title) {
            Picker("", selection: selection) {
                ForEach(shortcutKeys, id: \.self) { key in
                    Text(key).tag(key)
                }
            }
            .labelsHidden()
            .frame(width: 90)
        }
    }

    private var actionsSection: some View {
        HStack {
            Spacer()
            Button(saved ? "Saved" : "Save") { save() }
            Button("Restore Defaults") { restoreDefaults() }
        }
    }

    private var shortcutKeys: [String] {
        "ABCDEFGHIJKLMNOPQRSTUVWXYZ".map(String.init)
    }

    private var visibleHistoryItems: [TranslationHistoryItem] {
        historyStore.search(historySearch, favoritesOnly: showingFavoritesOnly)
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
        settings.selectionHotKey = selectionHotKey
        settings.screenshotHotKey = screenshotHotKey
        settings.glossaryText = glossaryText
        historyStore.isEnabled = historyEnabled
        onShortcutsChanged()
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

    private func testFreeProvider() {
        testingFreeProvider = true
        freeProviderStatus = ""
        Task {
            do {
                _ = try await freeTranslation.translate(
                    text: "hello",
                    targetLanguage: targetLanguage,
                    config: freeProviderConfig
                )
                await MainActor.run { freeProviderStatus = "Free provider available." }
            } catch {
                await MainActor.run { freeProviderStatus = error.localizedDescription }
            }
            await MainActor.run { testingFreeProvider = false }
        }
    }

    private func compareProviders() {
        testingComparison = true
        comparisonStatus = ""
        Task {
            var results: [String] = []
            for config in comparisonConfigs {
                do {
                    let output = try await freeTranslation.translate(text: "hello", targetLanguage: targetLanguage, config: config)
                    results.append("\(config.provider.displayName): \(output)")
                } catch {
                    results.append("\(config.provider.displayName): \(error.localizedDescription)")
                }
            }
            await MainActor.run {
                comparisonStatus = results.joined(separator: " | ")
                testingComparison = false
            }
        }
    }

    private func restoreDefaults() {
        settings.resetToDefaults()
        baseURL = settings.baseURL.absoluteString
        model = settings.model
        targetLanguage = settings.targetLanguage
        freeTranslationProvider = settings.freeTranslationProvider
        youdaoAppID = settings.youdaoAppID
        youdaoSecret = ""
        baiduAppID = settings.baiduAppID
        baiduSecret = ""
        apiKey = ""
        useAPIFallback = settings.useAPIFallback
        screenshotPopoverOpacity = settings.screenshotPopoverOpacity
        selectionHotKey = settings.selectionHotKey
        screenshotHotKey = settings.screenshotHotKey
        historyEnabled = historyStore.isEnabled
        glossaryText = settings.glossaryText
        apiStatus = ""
        freeProviderStatus = ""
        comparisonStatus = ""
        exportStatus = ""
        saved = false
    }

    private func clearHistory() {
        historyStore.clear()
        historyItems = []
        historySearch = ""
        showingFavoritesOnly = false
        exportStatus = "Cleared."
    }

    private func exportHistory(favoritesOnly: Bool) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = favoritesOnly ? "textlens-favorites.txt" : "textlens-history.txt"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try historyStore.exportText(favoritesOnly: favoritesOnly).write(to: url, atomically: true, encoding: .utf8)
            exportStatus = "Exported."
        } catch {
            exportStatus = error.localizedDescription
        }
    }

    private var strategySummary: String {
        useAPIFallback ? "\(freeTranslationProvider.displayName) first, API fallback enabled" : "\(freeTranslationProvider.displayName) first"
    }

    private var fallbackOrder: String {
        let backupProviders = [FreeTranslationProvider.google, .myMemory]
            .filter { $0 != freeTranslationProvider }
            .map(\.displayName)
        let apiFallback = useAPIFallback ? ["API fallback"] : []
        return ([freeTranslationProvider.displayName] + backupProviders + apiFallback).joined(separator: " > ")
    }

    private var freeProviderConfig: FreeTranslationService.Config {
        FreeTranslationService.Config(
            provider: freeTranslationProvider,
            youdaoAppID: youdaoAppID,
            youdaoSecret: youdaoSecret,
            baiduAppID: baiduAppID,
            baiduSecret: baiduSecret
        )
    }

    private var comparisonConfigs: [FreeTranslationService.Config] {
        var providers = [freeTranslationProvider, .google, .myMemory]
        providers = providers.reduce(into: []) { result, provider in
            if !result.contains(provider) {
                result.append(provider)
            }
        }
        return providers.map {
            FreeTranslationService.Config(
                provider: $0,
                youdaoAppID: youdaoAppID,
                youdaoSecret: youdaoSecret,
                baiduAppID: baiduAppID,
                baiduSecret: baiduSecret
            )
        }
    }

    private func clampedOpacity(_ value: Double) -> Double {
        min(max((value * 10).rounded() / 10, 0.1), 1.0)
    }
}
