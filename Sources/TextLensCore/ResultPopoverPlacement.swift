import CoreGraphics

public enum ResultPopoverPlacement {
    public static func frame(size: CGSize, point: CGPoint, anchor: CGRect?, visibleFrame: CGRect) -> CGRect {
        let origin = anchor.map { CGPoint(x: $0.minX, y: $0.minY - size.height - 12) } ?? CGPoint(x: point.x + 12, y: point.y - size.height)
        return CGRect(
            x: min(max(origin.x, visibleFrame.minX), visibleFrame.maxX - size.width),
            y: min(max(origin.y, visibleFrame.minY), visibleFrame.maxY - size.height),
            width: size.width,
            height: size.height
        )
    }
}
