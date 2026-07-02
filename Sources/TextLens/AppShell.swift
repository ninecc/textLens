import AppKit
import SwiftUI
import TextLensCore

final class AppShell: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var settingsWindow: NSWindow?
    private let settings = SettingsStore()
    private let keychain = KeychainStore()
    private let translation = TranslationService()
    private let ocr = OCRService()
    private let popover = ResultPopover()
    private let hotKeyCenter = HotKeyCenter()
    private lazy var selectionTranslator = SelectionTranslator(
        settings: settings,
        keychain: keychain,
        translation: translation,
        popover: popover
    )
    private lazy var screenCaptureTranslator = ScreenCaptureTranslator(
        settings: settings,
        keychain: keychain,
        ocr: ocr,
        translation: translation,
        popover: popover
    )

    func applicationDidFinishLaunching(_ notification: Notification) {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "TextLens"

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
        let view = SettingsView(settings: settings, keychain: keychain)
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 460, height: 260), styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.title = "TextLens Settings"
        window.contentView = NSHostingView(rootView: view)
        window.center()
        window.makeKeyAndOrderFront(nil)
        settingsWindow = window
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}
