import Foundation

public struct SupportedLanguage: Equatable, Identifiable {
    public let name: String
    public let displayName: String
    public let languageCode: String

    public var id: String { name }

    public static let unitedNations: [SupportedLanguage] = [
        .init(name: "Arabic", displayName: "العربية", languageCode: "ar"),
        .init(name: "Chinese", displayName: "中文", languageCode: "zh"),
        .init(name: "English", displayName: "English", languageCode: "en"),
        .init(name: "French", displayName: "Français", languageCode: "fr"),
        .init(name: "Russian", displayName: "Русский", languageCode: "ru"),
        .init(name: "Spanish", displayName: "Español", languageCode: "es")
    ]

    public static func normalized(_ name: String) -> SupportedLanguage {
        unitedNations.first { $0.name == name || $0.displayName == name } ?? unitedNations[1]
    }
}
