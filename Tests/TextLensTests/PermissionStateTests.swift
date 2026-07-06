import XCTest
@testable import TextLensCore

final class PermissionStateTests: XCTestCase {
    func testDisplayName() {
        XCTAssertEqual(PermissionState.granted.displayName, "Granted")
        XCTAssertEqual(PermissionState.missing.displayName, "Missing")
    }

    func testIsGranted() {
        XCTAssertTrue(PermissionState.granted.isGranted)
        XCTAssertFalse(PermissionState.missing.isGranted)
    }
}
