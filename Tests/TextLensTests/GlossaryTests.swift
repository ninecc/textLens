import XCTest
@testable import TextLensCore

final class GlossaryTests: XCTestCase {
    func testAppliesPreferredTranslationsLongestFirst() {
        let glossary = Glossary(entries: [
            .init(source: "API", preferred: "接口"),
            .init(source: "API fallback", preferred: "接口兜底")
        ])

        XCTAssertEqual(glossary.apply(to: "Use API fallback when API fails."), "Use 接口兜底 when 接口 fails.")
    }
}
