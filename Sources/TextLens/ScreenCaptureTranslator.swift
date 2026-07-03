import AppKit
import TextLensCore

final class ScreenCaptureTranslator {
    private let settings: SettingsStore
    private let ocr: OCRService
    private let translation: TranslationRunner
    private let popover: ResultPopover
    private var selectionWindow: RegionSelectionWindow?

    init(settings: SettingsStore, ocr: OCRService, translation: TranslationService, popover: ResultPopover) {
        self.settings = settings
        self.ocr = ocr
        self.translation = TranslationRunner(settings: settings, api: translation)
        self.popover = popover
    }

    func start() {
        guard CGPreflightScreenCaptureAccess() else {
            CGRequestScreenCaptureAccess()
            popover.show(original: "", translated: "Screen Recording permission is required.")
            return
        }

        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(NSEvent.mouseLocation) }) else {
            popover.show(original: "", translated: "Could not find the current screen.")
            return
        }

        let window = RegionSelectionWindow(screen: screen) { [weak self] rect in
            DispatchQueue.main.async {
                self?.selectionWindow?.close()
                self?.selectionWindow = nil
                guard let rect else { return }
                self?.translate(region: rect, on: screen)
            }
        }
        selectionWindow = window
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(window.contentView)
    }

    private func translate(region: CGRect, on screen: NSScreen) {
        guard let image = capture(region: region, on: screen) else {
            popover.show(original: "", translated: "Could not capture the selected region.")
            return
        }

        Task {
            do {
                let text = try await ocr.recognizeText(in: image)
                guard !text.isEmpty else {
                    await MainActor.run {
                        popover.show(original: "", translated: "No text recognized.")
                    }
                    return
                }
                let translated = try await translation.translate(text)
                await MainActor.run {
                    popover.show(original: text, translated: translated)
                }
            } catch {
                await MainActor.run {
                    popover.show(original: "", translated: error.localizedDescription)
                }
            }
        }
    }

    private func capture(region: CGRect, on screen: NSScreen) -> NSImage? {
        let globalRect = CGRect(
            x: screen.frame.minX + region.minX,
            y: screen.frame.minY + region.minY,
            width: region.width,
            height: region.height
        )
        guard let image = CGWindowListCreateImage(globalRect, .optionOnScreenOnly, kCGNullWindowID, [.bestResolution]) else {
            return nil
        }
        return NSImage(cgImage: image, size: globalRect.size)
    }
}
