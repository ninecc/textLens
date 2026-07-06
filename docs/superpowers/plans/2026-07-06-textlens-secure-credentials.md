# TextLens Secure Credentials Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox syntax for tracking.

**Goal:** Store translation credentials in Keychain and make the API fallback settings easier to understand.

**Architecture:** Add a tiny Keychain wrapper in `TextLensCore`, inject it into `SettingsStore`, and keep non-sensitive preferences in `UserDefaults`. Keep the UI change small: rename the API pane labels so users understand that the API is a fallback, not the default translation engine.

**Tech Stack:** Swift 5.9, SwiftPM, Foundation, Security framework, SwiftUI, XCTest.

---

## File Structure

- Modify: `Package.swift`
  - Link `Security` where needed by the Swift target.
- Create: `Sources/TextLensCore/KeychainStore.swift`
  - Minimal get/set/delete wrapper for string secrets.
- Modify: `Sources/TextLensCore/SettingsStore.swift`
  - Store `apiKey`, `youdaoSecret`, and `baiduSecret` in Keychain.
  - Keep `baseURL`, `model`, language, provider IDs, and toggles in `UserDefaults`.
  - Migrate existing secret values from `UserDefaults` to Keychain on first read.
- Modify: `Sources/TextLens/SettingsView.swift`
  - Rename the API pane to `API Fallback`.
  - Rename `Use API fallback` to `Use API when free translation fails`.
  - Keep layout unchanged.
- Modify: `Tests/TextLensTests/SettingsStoreTests.swift`
  - Add tests for secret storage, reset, and migration.
- Create: `Tests/TextLensTests/InMemorySecretStore.swift`
  - Test double matching the Keychain interface.

## Task 1: Add Secret Store Boundary

**Files:**
- Create: `Sources/TextLensCore/KeychainStore.swift`
- Create: `Tests/TextLensTests/InMemorySecretStore.swift`
- Modify: `Sources/TextLensCore/SettingsStore.swift`

- [x] **Step 1: Write the failing test double and secret storage test**

Add this helper:

```swift
// Tests/TextLensTests/InMemorySecretStore.swift
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
```

Add this test:

```swift
func testSecretsAreStoredOutsideUserDefaults() {
    let defaults = UserDefaults(suiteName: UUID().uuidString)!
    let secrets = InMemorySecretStore()
    let store = SettingsStore(defaults: defaults, secrets: secrets)

    store.apiKey = "api-secret"
    store.youdaoSecret = "youdao-secret"
    store.baiduSecret = "baidu-secret"

    XCTAssertEqual(secrets.values["apiKey"], "api-secret")
    XCTAssertEqual(secrets.values["youdaoSecret"], "youdao-secret")
    XCTAssertEqual(secrets.values["baiduSecret"], "baidu-secret")
    XCTAssertNil(defaults.string(forKey: "apiKey"))
    XCTAssertNil(defaults.string(forKey: "youdaoSecret"))
    XCTAssertNil(defaults.string(forKey: "baiduSecret"))
}
```

- [x] **Step 2: Run the focused test and verify it fails**

Run:

```bash
swift test --filter SettingsStoreTests/testSecretsAreStoredOutsideUserDefaults
```

Expected: compile fails because `SecretStore` and `SettingsStore(defaults:secrets:)` do not exist.

- [x] **Step 3: Add the minimal secret-store interface**

Add:

```swift
// Sources/TextLensCore/KeychainStore.swift
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
```

- [x] **Step 4: Inject the secret store into settings**

Change `SettingsStore` init and secret properties:

```swift
private let secrets: SecretStore

public init(defaults: UserDefaults = .standard, secrets: SecretStore = KeychainStore()) {
    self.defaults = defaults
    self.secrets = secrets
}

public var youdaoSecret: String {
    get { migratedSecret(forKey: Key.youdaoSecret) }
    set { secrets.setString(newValue, forKey: Key.youdaoSecret) }
}

public var baiduSecret: String {
    get { migratedSecret(forKey: Key.baiduSecret) }
    set { secrets.setString(newValue, forKey: Key.baiduSecret) }
}

public var apiKey: String {
    get { migratedSecret(forKey: Key.apiKey) }
    set { secrets.setString(newValue, forKey: Key.apiKey) }
}

private func migratedSecret(forKey key: String) -> String {
    let current = secrets.string(forKey: key)
    guard current.isEmpty, let old = defaults.string(forKey: key), !old.isEmpty else {
        return current
    }
    secrets.setString(old, forKey: key)
    defaults.removeObject(forKey: key)
    return old
}
```

Update `resetToDefaults()`:

```swift
secrets.removeString(forKey: Key.apiKey)
secrets.removeString(forKey: Key.youdaoSecret)
secrets.removeString(forKey: Key.baiduSecret)
```

- [x] **Step 5: Run the focused test and verify it passes**

Run:

```bash
swift test --filter SettingsStoreTests/testSecretsAreStoredOutsideUserDefaults
```

Expected: pass.

## Task 2: Migrate Existing UserDefaults Secrets

**Files:**
- Modify: `Tests/TextLensTests/SettingsStoreTests.swift`
- Modify: `Sources/TextLensCore/SettingsStore.swift`

- [x] **Step 1: Write the failing migration test**

Add:

```swift
func testReadsAndMigratesExistingUserDefaultsSecret() {
    let defaults = UserDefaults(suiteName: UUID().uuidString)!
    defaults.set("old-secret", forKey: "apiKey")
    let secrets = InMemorySecretStore()
    let store = SettingsStore(defaults: defaults, secrets: secrets)

    XCTAssertEqual(store.apiKey, "old-secret")
    XCTAssertEqual(secrets.values["apiKey"], "old-secret")
    XCTAssertNil(defaults.string(forKey: "apiKey"))
}
```

- [x] **Step 2: Run the focused test and verify it fails**

Run:

```bash
swift test --filter SettingsStoreTests/testReadsAndMigratesExistingUserDefaultsSecret
```

Expected: fail until `migratedSecret(forKey:)` is wired into `apiKey`.

- [x] **Step 3: Implement migration if Task 1 did not already cover it**

Use the `migratedSecret(forKey:)` helper from Task 1 for all three secret fields.

- [x] **Step 4: Run settings tests**

Run:

```bash
swift test --filter SettingsStoreTests
```

Expected: all `SettingsStoreTests` pass.

## Task 3: Clear Secrets On Reset

**Files:**
- Modify: `Tests/TextLensTests/SettingsStoreTests.swift`
- Modify: `Sources/TextLensCore/SettingsStore.swift`

- [x] **Step 1: Write the failing reset test**

Add:

```swift
func testResetClearsSecrets() {
    let defaults = UserDefaults(suiteName: UUID().uuidString)!
    let secrets = InMemorySecretStore()
    let store = SettingsStore(defaults: defaults, secrets: secrets)

    store.apiKey = "api-secret"
    store.youdaoSecret = "youdao-secret"
    store.baiduSecret = "baidu-secret"
    store.resetToDefaults()

    XCTAssertEqual(store.apiKey, "")
    XCTAssertEqual(store.youdaoSecret, "")
    XCTAssertEqual(store.baiduSecret, "")
    XCTAssertTrue(secrets.values.isEmpty)
}
```

- [x] **Step 2: Run the focused test and verify it fails**

Run:

```bash
swift test --filter SettingsStoreTests/testResetClearsSecrets
```

Expected: fail until reset removes Keychain-backed secrets.

- [x] **Step 3: Implement reset secret removal**

Add the three `secrets.removeString` calls to `resetToDefaults()`.

- [x] **Step 4: Run settings tests**

Run:

```bash
swift test --filter SettingsStoreTests
```

Expected: all `SettingsStoreTests` pass.

## Task 4: Clarify API Fallback Copy

**Files:**
- Modify: `Sources/TextLens/SettingsView.swift`

- [x] **Step 1: Make the smallest UI text change**

Change:

```swift
case api = "API"
```

to:

```swift
case api = "API Fallback"
```

Change:

```swift
formRow("Use API fallback") {
```

to:

```swift
formRow("Use API when free translation fails") {
```

- [x] **Step 2: Build**

Run:

```bash
swift build --product TextLens
```

Expected: build succeeds.

## Task 5: Final Verification

**Files:**
- Verify all touched files.

- [x] **Step 1: Run all tests**

Run:

```bash
swift test
```

Expected: all tests pass.

- [x] **Step 2: Run checks**

Run:

```bash
swift run TextLensChecks
```

Expected: `ok`.

- [x] **Step 3: Review git diff**

Run:

```bash
git diff -- README.md docs/product-experience-report.md docs/superpowers/plans/2026-07-06-textlens-secure-credentials.md Sources/TextLensCore/KeychainStore.swift Sources/TextLensCore/SettingsStore.swift Sources/TextLens/SettingsView.swift Tests/TextLensTests/InMemorySecretStore.swift Tests/TextLensTests/SettingsStoreTests.swift
```

Expected: only the docs from the previous step plus this secure-credentials iteration.

## Self-Review

- Spec coverage: covers P0 secure credential storage and part of settings clarity. It intentionally does not cover onboarding, permission center, result popover, or menu bar status.
- Placeholder scan: no placeholders.
- Type consistency: `SecretStore`, `KeychainStore`, and injected `SettingsStore(defaults:secrets:)` are defined before use.

## Completion Record

- Completed in commit `efc64ac feat: store translation secrets in keychain`.
- Verified with `swift build --product TextLens`.
- Verified with `swift test`: 24 tests, 0 failures.
- Verified with `swift run TextLensChecks`: `ok`.
