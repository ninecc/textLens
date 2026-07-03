import CoreGraphics
import TextLensCore
import XCTest

final class ScreenshotRegionTests: XCTestCase {
    func testCaptureRectFlipsRegionYWithinScreenFrame() {
        let rect = ScreenshotRegion.captureRect(
            region: CGRect(x: 40, y: 600, width: 200, height: 100),
            screenFrame: CGRect(x: 0, y: 0, width: 1000, height: 800)
        )

        XCTAssertEqual(rect, CGRect(x: 40, y: 100, width: 200, height: 100))
    }

    func testCaptureRectKeepsScreenOriginOffset() {
        let rect = ScreenshotRegion.captureRect(
            region: CGRect(x: 10, y: 50, width: 80, height: 30),
            screenFrame: CGRect(x: 100, y: 200, width: 500, height: 400)
        )

        XCTAssertEqual(rect, CGRect(x: 110, y: 520, width: 80, height: 30))
    }
}
