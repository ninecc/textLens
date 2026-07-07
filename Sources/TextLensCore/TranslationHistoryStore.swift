import Foundation

public struct TranslationHistoryItem: Codable, Equatable, Identifiable {
    public let id: UUID
    public let date: Date
    public let original: String
    public let translated: String
    public let isFavorite: Bool

    public init(id: UUID = UUID(), date: Date = Date(), original: String, translated: String, isFavorite: Bool = false) {
        self.id = id
        self.date = date
        self.original = original
        self.translated = translated
        self.isFavorite = isFavorite
    }

    private enum CodingKeys: String, CodingKey {
        case id, date, original, translated, isFavorite
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        date = try container.decode(Date.self, forKey: .date)
        original = try container.decode(String.self, forKey: .original)
        translated = try container.decode(String.self, forKey: .translated)
        isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
    }
}

public final class TranslationHistoryStore {
    private enum Key {
        static let items = "translationHistoryItems"
        static let enabled = "translationHistoryEnabled"
    }

    private let defaults: UserDefaults
    private let limit: Int

    public init(defaults: UserDefaults = .standard, limit: Int = 20) {
        self.defaults = defaults
        self.limit = limit
    }

    public var isEnabled: Bool {
        get { defaults.object(forKey: Key.enabled) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.enabled) }
    }

    public var items: [TranslationHistoryItem] {
        get {
            guard let data = defaults.data(forKey: Key.items),
                  let items = try? JSONDecoder().decode([TranslationHistoryItem].self, from: data) else {
                return []
            }
            return items
        }
        set { save(trimmed(newValue)) }
    }

    @discardableResult
    public func add(original: String, translated: String) -> TranslationHistoryItem {
        let existing = items.first { $0.original == original && $0.translated == translated }
        if !isEnabled {
            return existing ?? TranslationHistoryItem(original: original, translated: translated)
        }
        let item = TranslationHistoryItem(original: original, translated: translated, isFavorite: existing?.isFavorite ?? false)
        items = [item] + items.filter { $0.original != original || $0.translated != translated }
        return item
    }

    public func item(id: UUID) -> TranslationHistoryItem? {
        items.first { $0.id == id }
    }

    public func toggleFavorite(id: UUID) -> TranslationHistoryItem? {
        var updated: TranslationHistoryItem?
        items = items.map { item in
            guard item.id == id else { return item }
            updated = TranslationHistoryItem(
                id: item.id,
                date: item.date,
                original: item.original,
                translated: item.translated,
                isFavorite: !item.isFavorite
            )
            return updated!
        }
        return updated
    }

    public func search(_ query: String, favoritesOnly: Bool = false) -> [TranslationHistoryItem] {
        let source = favoritesOnly ? items.filter(\.isFavorite) : items
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return source }
        return source.filter {
            $0.original.localizedCaseInsensitiveContains(trimmed)
                || $0.translated.localizedCaseInsensitiveContains(trimmed)
        }
    }

    public func clear() {
        defaults.removeObject(forKey: Key.items)
    }

    public func exportText(favoritesOnly: Bool = false) -> String {
        search("", favoritesOnly: favoritesOnly)
            .map { "Original:\n\($0.original)\n\nTranslation:\n\($0.translated)" }
            .joined(separator: "\n\n---\n\n")
    }

    private func trimmed(_ items: [TranslationHistoryItem]) -> [TranslationHistoryItem] {
        var keptRecent = 0
        return items.filter { item in
            if item.isFavorite { return true }
            guard keptRecent < limit else { return false }
            keptRecent += 1
            return true
        }
    }

    private func save(_ items: [TranslationHistoryItem]) {
        guard let data = try? JSONEncoder().encode(items) else { return }
        defaults.set(data, forKey: Key.items)
    }
}
