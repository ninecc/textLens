import AppKit
import TextLensCore

final class SelectionTranslator {
    private let settings: SettingsStore
    private let keychain: KeychainStore
    private let translation: TranslationService
    private let popover: ResultPopover

    init(settings: SettingsStore, keychain: KeychainStore, translation: TranslationService, popover: ResultPopover) {
        self.settings = settings
        self.keychain = keychain
        self.translation = translation
        self.popover = popover
    }

    func translateClipboard() {
        translate(text: NSPasteboard.general.string(forType: .string) ?? "")
    }

    func translateSelection() {
        if let text = selectedText(), !text.isEmpty {
            translate(text: text)
        } else {
            popover.show(original: "", translated: "Could not read selection. Copy text, then use Translate Clipboard.")
        }
    }

    private func selectedText() -> String? {
        guard AXIsProcessTrusted() else { return nil }
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

    private func translate(text: String) {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            popover.show(original: "", translated: "No text to translate.")
            return
        }
        guard !keychain.apiKey.isEmpty else {
            popover.show(original: text, translated: "Missing API key. Open Settings.")
            return
        }

        Task {
            do {
                let translated = try await translation.translate(
                    text: text,
                    targetLanguage: settings.targetLanguage,
                    config: .init(baseURL: settings.baseURL, apiKey: keychain.apiKey, model: settings.model)
                )
                await MainActor.run {
                    popover.show(original: text, translated: translated)
                }
            } catch {
                await MainActor.run {
                    popover.show(original: text, translated: error.localizedDescription)
                }
            }
        }
    }
}
