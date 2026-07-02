import AppKit

final class ResultPopover {
    private var window: NSWindow?
    private var translatedText = ""

    func show(original: String, translated: String) {
        DispatchQueue.main.async { [weak self] in
            self?.present(original: original, translated: translated)
        }
    }

    private func present(original: String, translated: String) {
        translatedText = translated

        let textView = NSTextView(frame: NSRect(x: 12, y: 44, width: 376, height: 180))
        textView.isEditable = false
        textView.string = original.isEmpty ? translated : "Original:\n\(original)\n\nTranslation:\n\(translated)"

        let copyButton = NSButton(frame: NSRect(x: 12, y: 12, width: 80, height: 24))
        copyButton.title = "Copy"
        copyButton.target = self
        copyButton.action = #selector(copyTranslation)

        let closeButton = NSButton(frame: NSRect(x: 308, y: 12, width: 80, height: 24))
        closeButton.title = "Close"
        closeButton.target = self
        closeButton.action = #selector(close)

        let content = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 236))
        content.addSubview(textView)
        content.addSubview(copyButton)
        content.addSubview(closeButton)

        let point = NSEvent.mouseLocation
        let size = NSSize(width: 400, height: 236)
        let visibleFrame = NSScreen.screens.first(where: { $0.frame.contains(point) })?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero
        let frame = NSRect(
            x: min(max(point.x + 12, visibleFrame.minX), visibleFrame.maxX - size.width),
            y: min(max(point.y - size.height, visibleFrame.minY), visibleFrame.maxY - size.height),
            width: size.width,
            height: size.height
        )
        let window = NSPanel(contentRect: frame, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.hasShadow = true
        window.backgroundColor = .windowBackgroundColor
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
