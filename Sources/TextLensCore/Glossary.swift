import Foundation

public struct GlossaryEntry: Codable, Equatable {
    public let source: String
    public let preferred: String

    public init(source: String, preferred: String) {
        self.source = source
        self.preferred = preferred
    }
}

public struct Glossary {
    public let entries: [GlossaryEntry]

    public init(entries: [GlossaryEntry]) {
        self.entries = entries
    }

    public init(text: String) {
        entries = text
            .split(whereSeparator: \.isNewline)
            .compactMap { line in
                let parts = line.split(separator: "=", maxSplits: 1).map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
                guard parts.count == 2, !parts[0].isEmpty else { return nil }
                return GlossaryEntry(source: parts[0], preferred: parts[1])
            }
    }

    public func apply(to text: String) -> String {
        entries
            .sorted { $0.source.count > $1.source.count }
            .reduce(text) { output, entry in
                output.replacingOccurrences(of: entry.source, with: entry.preferred)
            }
    }
}
