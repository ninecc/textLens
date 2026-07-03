import CoreGraphics
import TextLensCore
import XCTest

final class ResultPopoverPlacementTests: XCTestCase {
    func testFrameUsesAnchorWhenProvided() {
        let frame = ResultPopoverPlacement.frame(
            size: CGSize(width: 400, height: 236),
            point: CGPoint(x: 20, y: 20),
            anchor: CGRect(x: 100, y: 300, width: 80, height: 40),
            visibleFrame: CGRect(x: 0, y: 0, width: 1000, height: 800)
        )

        XCTAssertEqual(frame.origin.x, 100)
        XCTAssertEqual(frame.origin.y, 52)
    }

    func testFrameKeepsWindowVisibleNearEdges() {
        let frame = ResultPopoverPlacement.frame(
            size: CGSize(width: 400, height: 236),
            point: CGPoint(x: 990, y: 10),
            anchor: nil,
            visibleFrame: CGRect(x: 0, y: 0, width: 1000, height: 800)
        )

        XCTAssertEqual(frame.origin.x, 600)
        XCTAssertEqual(frame.origin.y, 0)
    }
}
