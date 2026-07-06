import AppKit
import TextLensCore

final class ScreenCaptureTranslator {
    private let settings: SettingsStore
    private let ocr: OCRService
    private let translation: TranslationRunner
    private let popover: ResultPopover
    private let historyStore: TranslationHistoryStore
    private var selectionWindows: [RegionSelectionWindow] = []
    private var popoverOpacity: Double { settings.screenshotPopoverOpacity }

    init(settings: SettingsStore, ocr: OCRService, translation: TranslationService, popover: ResultPopover, historyStore: TranslationHistoryStore) {
        self.settings = settings
        self.ocr = ocr
        self.translation = TranslationRunner(settings: settings, api: translation)
        self.popover = popover
        self.historyStore = historyStore
    }

    func start() {
        guard CGPreflightScreenCaptureAccess() else {
            CGRequestScreenCaptureAccess()
            popover.show(
                original: "",
                translated: "Enable Screen Recording in TextLens Settings, then try Screenshot Translate again.",
                backgroundOpacity: popoverOpacity
            )
            return
        }

        selectionWindows = NSScreen.screens.map { screen in
            RegionSelectionWindow(screen: screen) { [weak self] rect in
                DispatchQueue.main.async {
                    self?.closeSelectionWindows()
                    guard let rect else { return }
                    self?.translate(region: rect, on: screen)
                }
            }
        }
        NSApp.activate(ignoringOtherApps: true)
        selectionWindows.forEach { window in
            window.makeKeyAndOrderFront(nil)
            window.makeFirstResponder(window.contentView)
        }
    }

    private func translate(region: CGRect, on screen: NSScreen) {
        let anchor = anchorRect(region: region, on: screen)
        let displayID = screenDisplayID(screen)
        guard let image = capture(region: region, on: screen) else {
            popover.show(
                original: "",
                translated: "Could not capture the selected region. Check Screen Recording permission, then retry.",
                anchor: anchor,
                backgroundOpacity: popoverOpacity,
                retry: { [weak self] in self?.retry(region: region, displayID: displayID) }
            )
            return
        }

        popover.show(original: "", translated: "Recognizing text...", anchor: anchor, backgroundOpacity: popoverOpacity, isLoading: true)
        Task {
            do {
                let text = try await ocr.recognizeText(in: image)
                guard !text.isEmpty else {
                    await MainActor.run {
                        popover.show(
                            original: "",
                            translated: "No text recognized. Select a clearer text region, then retry.",
                            anchor: anchor,
                            backgroundOpacity: popoverOpacity,
                            retry: { [weak self] in self?.retry(region: region, displayID: displayID) }
                        )
                    }
                    return
                }
                let editedText = await MainActor.run {
                    confirmOCRText(text) ?? ""
                }
                guard !editedText.isEmpty else { return }
                await MainActor.run {
                    popover.show(original: editedText, translated: "Translating...", anchor: anchor, backgroundOpacity: popoverOpacity, isLoading: true)
                    showKeychainHintIfNeeded(original: editedText, anchor: anchor)
                }
                let translated = try await translation.translate(editedText)
                await MainActor.run {
                    historyStore.add(original: editedText, translated: translated)
                    popover.show(original: editedText, translated: translated, anchor: anchor, backgroundOpacity: popoverOpacity)
                }
            } catch {
                await MainActor.run {
                    popover.show(
                        original: "",
                        translated: error.localizedDescription,
                        anchor: anchor,
                        backgroundOpacity: popoverOpacity,
                        retry: { [weak self] in self?.retry(region: region, displayID: displayID) }
                    )
                }
            }
        }
    }

    private func retry(region: CGRect, displayID: CGDirectDisplayID?) {
        guard let displayID,
              let screen = NSScreen.screens.first(where: { screenDisplayID($0) == displayID }) else {
            start()
            return
        }
        translate(region: region, on: screen)
    }

    private func closeSelectionWindows() {
        selectionWindows.forEach { $0.close() }
        selectionWindows = []
    }

    private func confirmOCRText(_ text: String) -> String? {
        let alert = NSAlert()
        alert.messageText = "Confirm OCR Text"
        alert.informativeText = "Edit recognized text before translation."
        alert.addButton(withTitle: "Translate")
        alert.addButton(withTitle: "Cancel")

        let scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 420, height: 160))
        let textView = NSTextView(frame: scrollView.bounds)
        textView.string = text
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        alert.accessoryView = scrollView

        return alert.runModal() == .alertFirstButtonReturn
            ? textView.string.trimmingCharacters(in: .whitespacesAndNewlines)
            : nil
    }

    private func showKeychainHintIfNeeded(original: String, anchor: CGRect) {
        guard settings.freeTranslationProvider == .youdao || settings.freeTranslationProvider == .baidu || settings.useAPIFallback else {
            return
        }
        popover.show(
            original: original,
            translated: "macOS may ask for Keychain access to read your saved translation secret.",
            anchor: anchor,
            backgroundOpacity: popoverOpacity,
            isLoading: true
        )
    }

    private func capture(region: CGRect, on screen: NSScreen) -> CGImage? {
        guard let displayID = (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)
            .map({ CGDirectDisplayID(truncating: $0) }) else {
            return nil
        }
        guard let image = CGDisplayCreateImage(displayID) else {
            return nil
        }
        let rect = ScreenshotRegion.displayCaptureRect(
            region: region,
            screenSize: screen.frame.size,
            scale: screen.backingScaleFactor,
            imageSize: CGSize(width: image.width, height: image.height)
        )
        guard !rect.isNull, rect.width > 0, rect.height > 0 else {
            return nil
        }
        return image.cropping(to: rect)
    }

    private func anchorRect(region: CGRect, on screen: NSScreen) -> CGRect {
        CGRect(
            x: screen.frame.minX + region.minX,
            y: screen.frame.minY + region.minY,
            width: region.width,
            height: region.height
        )
    }

    private func screenDisplayID(_ screen: NSScreen) -> CGDirectDisplayID? {
        (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)
            .map { CGDirectDisplayID(truncating: $0) }
    }
}
