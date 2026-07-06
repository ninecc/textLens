import Foundation
import Security

public protocol SecretStore {
    func string(forKey key: String) -> String
    func setString(_ value: String, forKey key: String)
    func removeString(forKey key: String)
}

public final class KeychainStore: SecretStore {
    private let service: String

    public init(service: String = "com.textlens.app") {
        self.service = service
    }

    public func string(forKey key: String) -> String {
        var query = baseQuery(forKey: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return ""
        }
        return value
    }

    public func setString(_ value: String, forKey key: String) {
        removeString(forKey: key)
        guard !value.isEmpty else { return }

        var query = baseQuery(forKey: key)
        query[kSecValueData as String] = Data(value.utf8)
        SecItemAdd(query as CFDictionary, nil)
    }

    public func removeString(forKey key: String) {
        SecItemDelete(baseQuery(forKey: key) as CFDictionary)
    }

    private func baseQuery(forKey key: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
    }
}
