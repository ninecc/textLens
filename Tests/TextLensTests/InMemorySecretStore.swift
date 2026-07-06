import TextLensCore

final class InMemorySecretStore: SecretStore {
    var values: [String: String] = [:]

    func string(forKey key: String) -> String {
        values[key] ?? ""
    }

    func setString(_ value: String, forKey key: String) {
        values[key] = value
    }

    func removeString(forKey key: String) {
        values.removeValue(forKey: key)
    }
}
