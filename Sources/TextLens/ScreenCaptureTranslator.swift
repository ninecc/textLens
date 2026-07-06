import AppKit
import TextLensCore

final class ScreenCaptureTranslator {
    private let settings: SettingsStore
    private let ocr: OCRService
    private let translation: TranslationRunner
    private let popover: ResultPopover
    private var selectionWindow: RegionSelectionWindow?
    private var popoverOpacity: Double { settings.screenshotPopoverOpacity }

    init(settings: SettingsStore, ocr: OCRService, translation: TranslationService, popover: ResultPopover) {
        self.settings = settings
        self.ocr = ocr
        self.translation = TranslationRunner(settings: settings, api: translation)
        self.popover = popover
    }

    func start() {
        guard CGPreflightScreenCaptureAccess() else {
            CGRequestScreenCaptureAccess()
            popover.show(original: "", translated: "Screen Recording permission is required.", backgroundOpacity: popoverOpacity)
            return
        }

        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(NSEvent.mouseLocation) }) else {
            popover.show(original: "", translated: "Could not find the current screen.", backgroundOpacity: popoverOpacity)
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
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(window.contentView)
    }

    private func translate(region: CGRect, on screen: NSScreen) {
        let anchor = anchorRect(region: region, on: screen)
        guard let image = capture(region: region, on: screen) else {
            popover.show(original: "", translated: "Could not capture the selected region.", anchor: anchor, backgroundOpacity: popoverOpacity)
            return
        }

        popover.show(original: "", translated: "Recognizing text...", anchor: anchor, backgroundOpacity: popoverOpacity)
        Task {
            do {
                let text = try await ocr.recognizeText(in: image)
                guard !text.isEmpty else {
                    await MainActor.run {
                        popover.show(original: "", translated: "No text recognized.", anchor: anchor, backgroundOpacity: popoverOpacity)
                    }
                    return
                }
                await MainActor.run {
                    popover.show(original: text, translated: "Translating...", anchor: anchor, backgroundOpacity: popoverOpacity)
                }
                let translated = try await translation.translate(text)
                await MainActor.run {
                    popover.show(original: text, translated: translated, anchor: anchor, backgroundOpacity: popoverOpacity)
                }
            } catch {
                await MainActor.run {
                    popover.show(original: "", translated: error.localizedDescription, anchor: anchor, backgroundOpacity: popoverOpacity)
                }
            }
        }
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
}
