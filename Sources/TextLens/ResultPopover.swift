import AppKit
import TextLensCore

final class ResultPopover: NSObject {
    private var window: NSWindow?
    private var translatedText = ""

    func show(original: String, translated: String, anchor: CGRect? = nil) {
        DispatchQueue.main.async { [weak self] in
            self?.present(original: original, translated: translated, anchor: anchor)
        }
    }

    private func present(original: String, translated: String, anchor: CGRect?) {
        window?.close()
        window = nil
        translatedText = translated

        let text = NSTextField(labelWithString: original.isEmpty ? translated : "Original:\n\(original)\n\nTranslation:\n\(translated)")
        text.frame = NSRect(x: 12, y: 44, width: 376, height: 180)
        text.lineBreakMode = .byWordWrapping
        text.maximumNumberOfLines = 0

        let copyButton = NSButton(frame: NSRect(x: 12, y: 12, width: 80, height: 24))
        copyButton.title = "Copy"
        copyButton.target = self
        copyButton.action = #selector(copyTranslation)

        let closeButton = NSButton(frame: NSRect(x: 308, y: 12, width: 80, height: 24))
        closeButton.title = "Close"
        closeButton.target = self
        closeButton.action = #selector(close)

        let content = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 236))
        content.addSubview(text)
        content.addSubview(copyButton)
        content.addSubview(closeButton)

        let point = NSEvent.mouseLocation
        let size = NSSize(width: 400, height: 236)
        let screenPoint = anchor.map { CGPoint(x: $0.midX, y: $0.midY) } ?? point
        let visibleFrame = NSScreen.screens.first(where: { $0.frame.contains(screenPoint) })?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero
        let frame = ResultPopoverPlacement.frame(size: size, point: point, anchor: anchor, visibleFrame: visibleFrame)
        let window = NSPanel(contentRect: frame, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.hasShadow = true
        window.isOpaque = false
        window.isMovableByWindowBackground = true
        window.backgroundColor = NSColor.windowBackgroundColor.withAlphaComponent(0.9)
        window.contentView = content
        window.orderFrontRegardless()
        self.window = window
    }

    @objc private func copyTranslation() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(translatedText, forType: .string)
    }

    @objc private func close() {
        window?.orderOut(nil)
        window = nil
    }
}
