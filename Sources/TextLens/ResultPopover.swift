import AppKit
import TextLensCore

final class ResultPopover: NSObject {
    private var window: NSWindow?
    private var expandedWindow: NSWindow?
    private var originalText = ""
    private var translatedText = ""
    private var retryAction: (() -> Void)?
    private var favoriteAction: (() -> Void)?

    func show(
        original: String,
        translated: String,
        anchor: CGRect? = nil,
        backgroundOpacity: Double = 0.9,
        isLoading: Bool = false,
        retry: (() -> Void)? = nil,
        favorite: (() -> Void)? = nil
    ) {
        DispatchQueue.main.async { [weak self] in
            self?.present(
                original: original,
                translated: translated,
                anchor: anchor,
                backgroundOpacity: backgroundOpacity,
                isLoading: isLoading,
                retry: retry,
                favorite: favorite
            )
        }
    }

    private func present(
        original: String,
        translated: String,
        anchor: CGRect?,
        backgroundOpacity: Double,
        isLoading: Bool,
        retry: (() -> Void)?,
        favorite: (() -> Void)?
    ) {
        window?.close()
        window = nil
        originalText = original
        translatedText = translated
        retryAction = retry
        favoriteAction = favorite

        let text = NSTextField(labelWithString: original.isEmpty ? translated : "Original:\n\(original)\n\nTranslation:\n\(translated)")
        text.frame = NSRect(x: 12, y: 44, width: 376, height: 180)
        text.lineBreakMode = .byWordWrapping
        text.maximumNumberOfLines = 0

        let copyOriginalButton = NSButton(frame: NSRect(x: 12, y: 12, width: 104, height: 24))
        copyOriginalButton.title = "Copy Original"
        copyOriginalButton.target = self
        copyOriginalButton.action = #selector(copyOriginal)
        copyOriginalButton.isEnabled = !original.isEmpty

        let copyTranslationButton = NSButton(frame: NSRect(x: 124, y: 12, width: 124, height: 24))
        copyTranslationButton.title = "Copy Translation"
        copyTranslationButton.target = self
        copyTranslationButton.action = #selector(copyTranslation)
        copyTranslationButton.isEnabled = !isLoading && !translated.isEmpty

        let retryButton = NSButton(frame: NSRect(x: 248, y: 12, width: 48, height: 24))
        retryButton.title = "Retry"
        retryButton.target = self
        retryButton.action = #selector(retryTranslation)
        retryButton.isEnabled = retry != nil && !isLoading

        let expandButton = NSButton(frame: NSRect(x: 300, y: 12, width: 56, height: 24))
        expandButton.title = "Expand"
        expandButton.target = self
        expandButton.action = #selector(expand)
        expandButton.isEnabled = !isLoading && (!original.isEmpty || !translated.isEmpty)

        let closeButton = NSButton(frame: NSRect(x: 360, y: 12, width: 36, height: 24))
        closeButton.title = "Close"
        closeButton.target = self
        closeButton.action = #selector(close)

        let content = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 236))
        content.addSubview(text)
        content.addSubview(copyOriginalButton)
        content.addSubview(copyTranslationButton)
        content.addSubview(retryButton)
        content.addSubview(expandButton)
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
        window.backgroundColor = NSColor.windowBackgroundColor.withAlphaComponent(min(max(backgroundOpacity, 0.1), 1.0))
        window.contentView = content
        window.orderFrontRegardless()
        self.window = window
    }

    @objc private func copyOriginal() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(originalText, forType: .string)
    }

    @objc private func copyTranslation() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(translatedText, forType: .string)
    }

    @objc private func copyAll() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(
            originalText.isEmpty ? translatedText : "Original:\n\(originalText)\n\nTranslation:\n\(translatedText)",
            forType: .string
        )
    }

    @objc private func retryTranslation() {
        retryAction?()
    }

    @objc private func expand() {
        expandedWindow?.close()
        let content = NSView(frame: NSRect(x: 0, y: 0, width: 680, height: 500))

        let textView = NSTextView(frame: NSRect(x: 16, y: 56, width: 648, height: 428))
        textView.string = originalText.isEmpty ? translatedText : "Original:\n\(originalText)\n\nTranslation:\n\(translatedText)"
        textView.isEditable = false
        textView.isRichText = false
        textView.textContainerInset = NSSize(width: 10, height: 10)

        let scrollView = NSScrollView(frame: textView.frame)
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false

        let copyButton = NSButton(frame: NSRect(x: 16, y: 16, width: 80, height: 28))
        copyButton.title = "Copy All"
        copyButton.target = self
        copyButton.action = #selector(copyAll)

        let retryButton = NSButton(frame: NSRect(x: 104, y: 16, width: 64, height: 28))
        retryButton.title = "Retry"
        retryButton.target = self
        retryButton.action = #selector(retryTranslation)
        retryButton.isEnabled = retryAction != nil

        let favoriteButton = NSButton(frame: NSRect(x: 176, y: 16, width: 80, height: 28))
        favoriteButton.title = "Favorite"
        favoriteButton.target = self
        favoriteButton.action = #selector(favoriteResult)
        favoriteButton.isEnabled = favoriteAction != nil

        content.addSubview(scrollView)
        content.addSubview(copyButton)
        content.addSubview(retryButton)
        content.addSubview(favoriteButton)

        let window = NSWindow(contentRect: content.frame, styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
        window.title = "TextLens Result"
        window.contentView = content
        window.center()
        window.makeKeyAndOrderFront(nil)
        expandedWindow = window
    }

    @objc private func favoriteResult() {
        favoriteAction?()
    }

    @objc private func close() {
        window?.orderOut(nil)
        window = nil
        retryAction = nil
        favoriteAction = nil
    }
}
