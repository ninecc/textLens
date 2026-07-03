import Foundation

public enum FreeTranslationProvider: String, CaseIterable, Identifiable {
    case google
    case myMemory
    case youdao
    case baidu

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .google: return "Google"
        case .myMemory: return "MyMemory"
        case .youdao: return "Youdao"
        case .baidu: return "Baidu"
        }
    }
}
