import Foundation

public struct TranslationHistoryItem: Codable, Equatable, Identifiable {
    public let id: UUID
    public let date: Date
    public let original: String
    public let translated: String

    public init(id: UUID = UUID(), date: Date = Date(), original: String, translated: String) {
        self.id = id
        self.date = date
        self.original = original
        self.translated = translated
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
        set { save(Array(newValue.prefix(limit))) }
    }

    public func add(original: String, translated: String) {
        guard isEnabled else { return }
        let item = TranslationHistoryItem(original: original, translated: translated)
        items = [item] + items.filter { $0.original != original || $0.translated != translated }
    }

    public func clear() {
        defaults.removeObject(forKey: Key.items)
    }

    public func exportText() -> String {
        items.map { "Original:\n\($0.original)\n\nTranslation:\n\($0.translated)" }
            .joined(separator: "\n\n---\n\n")
    }

    private func save(_ items: [TranslationHistoryItem]) {
        guard let data = try? JSONEncoder().encode(items) else { return }
        defaults.set(data, forKey: Key.items)
    }
}
