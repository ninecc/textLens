import AppKit
import TextLensCore

final class SelectionTranslator {
    private let settings: SettingsStore
    private let translation: TranslationRunner
    private let popover: ResultPopover
    private let historyStore: TranslationHistoryStore

    init(settings: SettingsStore, translation: TranslationService, popover: ResultPopover, historyStore: TranslationHistoryStore) {
        self.settings = settings
        self.translation = TranslationRunner(settings: settings, api: translation)
        self.popover = popover
        self.historyStore = historyStore
    }

    func translateClipboard() {
        translateText(NSPasteboard.general.string(forType: .string) ?? "")
    }

    func translateSelection() {
        guard accessibilityTrusted(prompt: true) else {
            popover.show(original: "", translated: "Enable Accessibility in TextLens Settings, then try Translate Selection again.")
            return
        }

        if let text = SelectionTextResolver.resolve(accessibilityText: selectedText, copiedText: copySelectedText) {
            translateText(text)
        } else {
            popover.show(original: "", translated: "Could not read selection. Copy text, then use Translate Clipboard.")
        }
    }

    private func selectedText() -> String? {
        // ponytail: AX selected text varies by app; clipboard fallback is the first-version escape hatch.
        let systemWide = AXUIElementCreateSystemWide()
        var focused: AnyObject?
        guard AXUIElementCopyAttributeValue(systemWide, kAXFocusedUIElementAttribute as CFString, &focused) == .success,
              let element = focused else {
            return nil
        }

        var selected: AnyObject?
        guard AXUIElementCopyAttributeValue(element as! AXUIElement, kAXSelectedTextAttribute as CFString, &selected) == .success else {
            return nil
        }
        return selected as? String
    }

    private func accessibilityTrusted(prompt: Bool) -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    private func copySelectedText() -> String? {
        let pasteboard = NSPasteboard.general
        let oldString = pasteboard.string(forType: .string)
        let oldChangeCount = pasteboard.changeCount

        postCopyShortcut()
        RunLoop.current.run(until: Date().addingTimeInterval(0.12))

        let copied = pasteboard.changeCount == oldChangeCount ? nil : pasteboard.string(forType: .string)
        restorePasteboard(oldString)
        return copied
    }

    private func postCopyShortcut() {
        guard let source = CGEventSource(stateID: .hidSystemState),
              let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 8, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 8, keyDown: false) else {
            return
        }
        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }

    private func restorePasteboard(_ text: String?) {
        NSPasteboard.general.clearContents()
        if let text {
            NSPasteboard.general.setString(text, forType: .string)
        }
    }

    func translateText(_ text: String) {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            popover.show(original: "", translated: "No text to translate.")
            return
        }
        popover.show(original: text, translated: "Translating...", isLoading: true)
        showKeychainHintIfNeeded(original: text)
        Task {
            do {
                let translated = try await translation.translate(text)
                await MainActor.run {
                    let item = historyStore.add(original: text, translated: translated)
                    popover.show(
                        original: text,
                        translated: translated,
                        retry: { [weak self] in self?.translateText(text) },
                        favorite: { [weak historyStore] in _ = historyStore?.toggleFavorite(id: item.id) }
                    )
                }
            } catch {
                await MainActor.run {
                    popover.show(
                        original: text,
                        translated: error.localizedDescription,
                        retry: { [weak self] in self?.translateText(text) }
                    )
                }
            }
        }
    }

    private func showKeychainHintIfNeeded(original: String) {
        guard settings.freeTranslationProvider == .youdao || settings.freeTranslationProvider == .baidu || settings.useAPIFallback else {
            return
        }
        popover.show(
            original: original,
            translated: "macOS may ask for Keychain access to read your saved translation secret.",
            isLoading: true
        )
    }
}
