import Foundation

public enum SelectionTextResolver {
    public static func resolve(accessibilityText: () -> String?, copiedText: () -> String?) -> String? {
        if let text = cleaned(accessibilityText()) {
            return text
        }
        return cleaned(copiedText())
    }

    private static func cleaned(_ text: String?) -> String? {
        guard let value = text?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
            return nil
        }
        return value
    }
}
