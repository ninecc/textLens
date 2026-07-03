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

    public static func displayCaptureRect(region: CGRect, screenSize: CGSize, scale: CGFloat) -> CGRect {
        CGRect(
            x: region.minX * scale,
            y: (screenSize.height - region.maxY) * scale,
            width: region.width * scale,
            height: region.height * scale
        )
    }

    public static func displayCaptureRect(region: CGRect, screenSize: CGSize, scale: CGFloat, imageSize: CGSize) -> CGRect {
        let rect = displayCaptureRect(region: region, screenSize: screenSize, scale: scale).integral
        return rect.intersection(CGRect(origin: .zero, size: imageSize))
    }
}
