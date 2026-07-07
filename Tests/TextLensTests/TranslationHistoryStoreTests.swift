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

    func testSearchMatchesOriginalAndTranslationCaseInsensitively() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let store = TranslationHistoryStore(defaults: defaults)
        store.add(original: "Hello world", translated: "你好世界")
        store.add(original: "Good morning", translated: "早上好")

        XCTAssertEqual(store.search("hello").map(\.original), ["Hello world"])
        XCTAssertEqual(store.search("早上").map(\.original), ["Good morning"])
    }

    func testFavoritesSurviveRecentHistoryLimit() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let store = TranslationHistoryStore(defaults: defaults, limit: 2)
        let favorite = store.add(original: "keep", translated: "保留")
        _ = store.toggleFavorite(id: favorite.id)

        store.add(original: "one", translated: "一")
        store.add(original: "two", translated: "二")
        store.add(original: "three", translated: "三")

        XCTAssertTrue(store.items.contains { $0.id == favorite.id && $0.isFavorite })
        XCTAssertEqual(store.items.filter { !$0.isFavorite }.map(\.original), ["three", "two"])
    }

    func testFavoriteFilterAndExportFavoritesOnly() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let store = TranslationHistoryStore(defaults: defaults)
        let first = store.add(original: "alpha", translated: "阿尔法")
        store.add(original: "beta", translated: "贝塔")
        _ = store.toggleFavorite(id: first.id)

        XCTAssertEqual(store.search("", favoritesOnly: true).map(\.original), ["alpha"])
        XCTAssertTrue(store.exportText(favoritesOnly: true).contains("alpha"))
        XCTAssertFalse(store.exportText(favoritesOnly: true).contains("beta"))
    }

    func testDisabledHistoryDoesNotAddNewNonFavoriteItems() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let store = TranslationHistoryStore(defaults: defaults)
        let existing = store.add(original: "saved", translated: "已保存")
        _ = store.toggleFavorite(id: existing.id)

        store.isEnabled = false
        _ = store.add(original: "ignored", translated: "忽略")

        XCTAssertEqual(store.items.map(\.original), ["saved"])
        XCTAssertTrue(store.items[0].isFavorite)
    }
}
