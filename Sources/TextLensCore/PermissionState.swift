public enum PermissionState: Equatable {
    case granted
    case missing

    public var displayName: String {
        switch self {
        case .granted: return "Granted"
        case .missing: return "Missing"
        }
    }

    public var isGranted: Bool {
        self == .granted
    }
}
