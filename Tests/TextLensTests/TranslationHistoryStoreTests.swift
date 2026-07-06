import XCTest
@testable import TextLensCore

final class TranslationHistoryStoreTests: XCTestCase {
    func testKeepsLatestTwentyItemsNewestFirst() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let store = TranslationHistoryStore(defaults: defaults)

        for index in 1...22 {
            store.add(original: "original \(index)", translated: "translated \(index)")
        }

        XCTAssertEqual(store.items.count, 20)
        XCTAssertEqual(store.items.first?.original, "original 22")
        XCTAssertEqual(store.items.last?.original, "original 3")
    }

    func testCanDisableAndClearHistory() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let store = TranslationHistoryStore(defaults: defaults)

        store.isEnabled = false
        store.add(original: "hello", translated: "你好")
        XCTAssertTrue(store.items.isEmpty)

        store.isEnabled = true
        store.add(original: "hello", translated: "你好")
        XCTAssertEqual(store.items.count, 1)

        store.clear()
        XCTAssertTrue(store.items.isEmpty)
    }
}
