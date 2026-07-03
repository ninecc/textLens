import AppKit
import SwiftUI
import TextLensCore

final class AppShell: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var settingsWindow: NSWindow?
    private let settings = SettingsStore()
    private let translation = TranslationService()
    private let ocr = OCRService()
    private let popover = ResultPopover()
    private let hotKeyCenter = HotKeyCenter()
    private lazy var selectionTranslator = SelectionTranslator(
        settings: settings,
        translation: translation,
        popover: popover
    )
    private lazy var screenCaptureTranslator = ScreenCaptureTranslator(
        settings: settings,
        ocr: ocr,
        translation: translation,
        popover: popover
    )

    func applicationDidFinishLaunching(_ notification: Notification) {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = .textLensStatusIcon
        item.button?.imagePosition = .imageOnly
        item.button?.toolTip = "TextLens"

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Translate Selection", action: #selector(translateSelection), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Translate Clipboard", action: #selector(translateClipboard), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Screenshot Translate", action: #selector(screenshotTranslate), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Settings", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))

        item.menu = menu
        statusItem = item
        hotKeyCenter.registerSelectionHotKey { [weak self] in
            self?.translateSelection()
        }
        hotKeyCenter.registerScreenshotHotKey { [weak self] in
            self?.screenshotTranslate()
        }
    }

    @objc private func translateSelection() {
        selectionTranslator.translateSelection()
    }

    @objc private func translateClipboard() {
        selectionTranslator.translateClipboard()
    }

    @objc private func screenshotTranslate() {
        screenCaptureTranslator.start()
    }

    @objc private func openSettings() {
        if let settingsWindow {
            NSApp.activate(ignoringOtherApps: true)
            settingsWindow.makeKeyAndOrderFront(nil)
            return
        }

        let view = SettingsView(settings: settings)
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 560, height: 420), styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.title = "TextLens Settings"
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.collectionBehavior = [.moveToActiveSpace]
        window.contentView = NSHostingView(rootView: view)
        window.center()
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        settingsWindow = window
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}

private extension NSImage {
    static var textLensStatusIcon: NSImage {
        let image = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { _ in
            NSColor.black.setStroke()

            let box = NSBezierPath(roundedRect: NSRect(x: 9.8, y: 10, width: 7.2, height: 5.4), xRadius: 1.6, yRadius: 1.6)
            box.lineWidth = 1.35
            box.stroke()

            let lines = NSBezierPath()
            lines.lineWidth = 1.5
            lines.lineCapStyle = .round
            lines.move(to: NSPoint(x: 2.2, y: 9.5))
            lines.line(to: NSPoint(x: 7.2, y: 9.5))
            lines.move(to: NSPoint(x: 2.2, y: 5.7))
            lines.line(to: NSPoint(x: 16, y: 5.7))
            lines.move(to: NSPoint(x: 5.8, y: 2.8))
            lines.line(to: NSPoint(x: 12.4, y: 2.8))
            lines.stroke()

            return true
        }
        image.isTemplate = true
        return image
    }
}
