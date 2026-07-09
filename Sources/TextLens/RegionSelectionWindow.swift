import AppKit

final class RegionSelectionWindow: NSWindow {
    let selectionScreen: NSScreen

    init(screen: NSScreen, isActive: Bool, onActivate: @escaping () -> Void, onSelect: @escaping (CGRect?) -> Void) {
        self.selectionScreen = screen
        let view = RegionSelectionView(
            frame: CGRect(origin: .zero, size: screen.frame.size),
            isActive: isActive,
            onActivate: onActivate,
            onSelect: onSelect
        )
        super.init(contentRect: screen.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        level = .screenSaver
        backgroundColor = .clear
        isOpaque = false
        isReleasedWhenClosed = false
        ignoresMouseEvents = false
        acceptsMouseMovedEvents = true
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        contentView = view
    }

    override var canBecomeKey: Bool { true }

    func setActive(_ isActive: Bool) {
        (contentView as? RegionSelectionView)?.setActive(isActive)
    }
}

private final class RegionSelectionView: NSView {
    private var isActive: Bool
    private let onActivate: () -> Void
    private let onSelect: (CGRect?) -> Void
    private var start: CGPoint?
    private var current: CGPoint?
    private var trackingArea: NSTrackingArea?

    init(frame: CGRect, isActive: Bool, onActivate: @escaping () -> Void, onSelect: @escaping (CGRect?) -> Void) {
        self.isActive = isActive
        self.onActivate = onActivate
        self.onSelect = onSelect
        super.init(frame: frame)
        wantsLayer = true
    }

    required init?(coder: NSCoder) {
        nil
    }

    override var acceptsFirstResponder: Bool { true }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func updateTrackingAreas() {
        if let trackingArea {
            removeTrackingArea(trackingArea)
        }
        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self
        )
        addTrackingArea(trackingArea)
        self.trackingArea = trackingArea
        super.updateTrackingAreas()
    }

    override func mouseEntered(with event: NSEvent) {
        activate()
    }

    override func mouseDown(with event: NSEvent) {
        activate()
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

    func setActive(_ isActive: Bool) {
        guard self.isActive != isActive else { return }
        self.isActive = isActive
        needsDisplay = true
    }

    private func activate() {
        guard !isActive else { return }
        onActivate()
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.black.withAlphaComponent(isActive ? 0.25 : 0.16).setFill()
        bounds.fill()

        if isActive {
            drawCancelHint()
        }

        guard let start, let current else { return }
        let rect = CGRect(
            x: min(start.x, current.x),
            y: min(start.y, current.y),
            width: abs(start.x - current.x),
            height: abs(start.y - current.y)
        )
        NSColor.clear.setFill()
        rect.fill(using: .copy)
        let path = NSBezierPath(rect: rect)
        path.lineWidth = 2
        NSColor.systemBlue.setStroke()
        path.stroke()
    }

    private func drawCancelHint() {
        let text = "Drag to select, Esc to cancel"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 14, weight: .medium),
            .foregroundColor: NSColor.white
        ]
        let textSize = text.size(withAttributes: attributes)
        let padding = NSSize(width: 14, height: 8)
        let bubble = NSRect(
            x: bounds.maxX - textSize.width - padding.width * 2 - 20,
            y: bounds.maxY - textSize.height - padding.height * 2 - 20,
            width: textSize.width + padding.width * 2,
            height: textSize.height + padding.height * 2
        )

        NSColor.black.withAlphaComponent(0.55).setFill()
        NSBezierPath(roundedRect: bubble, xRadius: 8, yRadius: 8).fill()
        text.draw(
            at: NSPoint(x: bubble.minX + padding.width, y: bubble.minY + padding.height),
            withAttributes: attributes
        )
    }
}
