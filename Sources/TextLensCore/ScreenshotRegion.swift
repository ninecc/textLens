import CoreGraphics

public enum ScreenshotRegion {
    public static func captureRect(region: CGRect, screenFrame: CGRect) -> CGRect {
        CGRect(
            x: screenFrame.minX + region.minX,
            y: screenFrame.maxY - region.maxY,
            width: region.width,
            height: region.height
        )
    }
}
