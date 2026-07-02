import XCTest
@testable import TextLensCore

final class SelectionTextResolverTests: XCTestCase {
    func testUsesCopiedTextWhenAccessibilityTextIsEmpty() {
        let text = SelectionTextResolver.resolve(
            accessibilityText: { "" },
            copiedText: { "copied selection" }
        )

        XCTAssertEqual(text, "copied selection")
    }

    func testPrefersAccessibilityText() {
        let text = SelectionTextResolver.resolve(
            accessibilityText: { "accessibility selection" },
            copiedText: { "copied selection" }
        )

        XCTAssertEqual(text, "accessibility selection")
    }
}
