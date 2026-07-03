import AppKit

final class RegionSelectionWindow: NSWindow {
    init(screen: NSScreen, onSelect: @escaping (CGRect?) -> Void) {
        let view = RegionSelectionView(frame: CGRect(origin: .zero, size: screen.frame.size), onSelect: onSelect)
        super.init(contentRect: screen.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        level = .screenSaver
        backgroundColor = .clear
        isOpaque = false
        isReleasedWhenClosed = false
        ignoresMouseEvents = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        contentView = view
    }

    override var canBecomeKey: Bool { true }
}

private final class RegionSelectionView: NSView {
    private let onSelect: (CGRect?) -> Void
    private var start: CGPoint?
    private var current: CGPoint?

    init(frame: CGRect, onSelect: @escaping (CGRect?) -> Void) {
        self.onSelect = onSelect
        super.init(frame: frame)
        wantsLayer = true
    }

    required init?(coder: NSCoder) {
        nil
    }

    override var acceptsFirstResponder: Bool { true }

    override func mouseDown(with event: NSEvent) {
        start = convert(event.locationInWindow, from: nil)
        current = start
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        current = convert(event.locationInWindow, from: nil)
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        current = convert(event.locationInWindow, from: nil)
        guard let start, let current else {
            onSelect(nil)
            return
        }
        let rect = CGRect(
            x: min(start.x, current.x),
            y: min(start.y, current.y),
            width: abs(start.x - current.x),
            height: abs(start.y - current.y)
        )
        onSelect(rect.width < 8 || rect.height < 8 ? nil : rect)
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            onSelect(nil)
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.black.withAlphaComponent(0.25).setFill()
        bounds.fill()

        guard let start, let current else { return }
        let rect = CGRect(
            x: min(start.x, current.x),
            y: min(start.y, current.y),
            width: abs(start.x - current.x),
            height: abs(start.y - current.y)
        )
        NSColor.clear.setFill()
        rect.fill(using: .copy)
        NSColor.systemBlue.setStroke()
        NSBezierPath(rect: rect).stroke()
    }
}
