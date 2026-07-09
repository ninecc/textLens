import AppKit
import TextLensCore

final class ResultPopover: NSObject {
    private var window: NSWindow?
    private var expandedWindow: NSWindow?
    private var originalText = ""
    private var translatedText = ""
    private var retryAction: (() -> Void)?
    private var editOriginalAction: (() -> Void)?
    private var reselectAction: (() -> Void)?
    private var favoriteAction: (() -> Void)?

    func show(
        original: String,
        translated: String,
        anchor: CGRect? = nil,
        backgroundOpacity: Double = 0.9,
        isLoading: Bool = false,
        retry: (() -> Void)? = nil,
        editOriginal: (() -> Void)? = nil,
        reselect: (() -> Void)? = nil,
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
                editOriginal: editOriginal,
                reselect: reselect,
                favorite: favorite
            )
        }
    }

    func dismissMain() {
        close()
    }

    private func present(
        original: String,
        translated: String,
        anchor: CGRect?,
        backgroundOpacity: Double,
        isLoading: Bool,
        retry: (() -> Void)?,
        editOriginal: (() -> Void)?,
        reselect: (() -> Void)?,
        favorite: (() -> Void)?
    ) {
        window?.close()
        window = nil
        originalText = original
        translatedText = translated
        retryAction = retry
        editOriginalAction = editOriginal
        reselectAction = reselect
        favoriteAction = favorite

        let usesScreenshotActions = reselect != nil || editOriginal != nil
        let contentHeight: CGFloat = usesScreenshotActions ? 268 : 236
        let buttonTopY: CGFloat = usesScreenshotActions ? 44 : 12
        let text = NSTextField(labelWithString: original.isEmpty ? translated : "Original:\n\(original)\n\nTranslation:\n\(translated)")
        text.frame = NSRect(x: 12, y: usesScreenshotActions ? 76 : 44, width: 424, height: 180)
        text.lineBreakMode = .byWordWrapping
        text.maximumNumberOfLines = 0

        let copyOriginalButton = button(
            "Copy Original",
            frame: NSRect(x: 12, y: buttonTopY, width: 120, height: 24),
            action: #selector(copyOriginal),
            enabled: !original.isEmpty
        )
        let copyTranslationButton = button(
            "Copy Translation",
            frame: NSRect(x: 140, y: buttonTopY, width: 136, height: 24),
            action: #selector(copyTranslation),
            enabled: !isLoading && !translated.isEmpty
        )
        let retryButton = button(
            "Retry",
            frame: NSRect(x: 256, y: 12, width: 48, height: 24),
            action: #selector(retryTranslation),
            enabled: retry != nil && !isLoading
        )
        let editOriginalButton = button(
            "Edit Original",
            frame: NSRect(x: 12, y: 12, width: 112, height: 24),
            action: #selector(editOriginalText),
            enabled: editOriginal != nil && !isLoading
        )
        let reselectButton = button(
            "Reselect",
            frame: NSRect(x: 132, y: 12, width: 88, height: 24),
            action: #selector(reselectRegion),
            enabled: reselect != nil && !isLoading
        )
        let expandButton = button(
            "Expand",
            frame: NSRect(x: 308, y: 12, width: 56, height: 24),
            action: #selector(expand),
            enabled: !usesScreenshotActions && !isLoading && (!original.isEmpty || !translated.isEmpty)
        )
        let closeButton = button(
            "Close",
            frame: NSRect(x: 372, y: 12, width: 68, height: 24),
            action: #selector(close)
        )

        let content = NSView(frame: NSRect(x: 0, y: 0, width: 448, height: contentHeight))
        content.addSubview(text)
        content.addSubview(copyOriginalButton)
        content.addSubview(copyTranslationButton)
        if usesScreenshotActions {
            content.addSubview(editOriginalButton)
            content.addSubview(reselectButton)
        } else {
            content.addSubview(retryButton)
            content.addSubview(expandButton)
        }
        content.addSubview(closeButton)

        let point = NSEvent.mouseLocation
        let size = NSSize(width: 448, height: contentHeight)
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

    private func button(_ title: String, frame: NSRect, action: Selector, enabled: Bool = true) -> NSButton {
        let button = NSButton(frame: frame)
        button.title = title
        button.target = self
        button.action = action
        button.isEnabled = enabled
        return button
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

    @objc private func editOriginalText() {
        editOriginalAction?()
    }

    @objc private func reselectRegion() {
        reselectAction?()
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

        let copyButton = button(
            "Copy All",
            frame: NSRect(x: 16, y: 16, width: 88, height: 28),
            action: #selector(copyAll),
            enabled: !originalText.isEmpty || !translatedText.isEmpty
        )

        let retryButton = button(
            "Retry",
            frame: NSRect(x: 112, y: 16, width: 72, height: 28),
            action: #selector(retryTranslation),
            enabled: retryAction != nil
        )

        let favoriteButton = button(
            "Favorite",
            frame: NSRect(x: 192, y: 16, width: 88, height: 28),
            action: #selector(favoriteResult),
            enabled: favoriteAction != nil
        )

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
        editOriginalAction = nil
        reselectAction = nil
        favoriteAction = nil
    }
}
