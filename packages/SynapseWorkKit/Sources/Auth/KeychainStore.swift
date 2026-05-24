import Foundation
import Security

public enum KeychainError: Error, Equatable, Sendable {
    case unexpectedStatus(OSStatus)
    case encodingFailure
}

/// Minimal Keychain wrapper around `SecItem*` for the synapse-work
/// session JWT, device id, and other small secrets. Items are scoped by
/// `service` and `account`. The default accessibility class is
/// `kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly` — secrets are
/// unavailable on a device with no user passcode and are excluded from
/// iCloud Keychain backup.
///
/// Access group: when `accessGroup` is non-nil the store passes
/// `kSecAttrAccessGroup` so all four Synapse binaries (life/work × iOS/mac)
/// signed with the matching `keychain-access-groups` entitlement share the
/// same items. `nil` keeps single-app behavior so unsigned `swift test`
/// runs that lack the entitlement pass.
public struct KeychainStore: Sendable {

    public let service: String
    public let accessibility: String
    public let accessGroup: String?

    /// Shared keychain group for the four Synapse binaries. Matches the
    /// `keychain-access-groups` entitlement in the work-iOS / work-mac
    /// `*.entitlements` files (owned by the entitlements agent; we
    /// reference the group by name only).
    public static let sharedAccessGroup: String = "tech.synapse.shared"

    public static let defaultAccessibility: String =
        kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly as String

    public init(
        service: String,
        accessibility: String = KeychainStore.defaultAccessibility,
        accessGroup: String? = nil
    ) {
        self.service = service
        self.accessibility = accessibility
        self.accessGroup = accessGroup
    }

    private func baseQuery(account: String) -> [String: Any] {
        var q: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        if let group = accessGroup {
            q[kSecAttrAccessGroup as String] = group
        }
        return q
    }

    public func write(key: String, data: Data) throws {
        let query = baseQuery(account: key)
        let attrs: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: self.accessibility
        ]
        let status = SecItemUpdate(query as CFDictionary, attrs as CFDictionary)
        switch status {
        case errSecSuccess:
            return
        case errSecItemNotFound:
            var add = query
            for (k, v) in attrs { add[k] = v }
            let addStatus = SecItemAdd(add as CFDictionary, nil)
            guard addStatus == errSecSuccess else { throw KeychainError.unexpectedStatus(addStatus) }
        default:
            throw KeychainError.unexpectedStatus(status)
        }
    }

    public func read(key: String) throws -> Data? {
        var query = baseQuery(account: key)
        query[kSecReturnData as String] = kCFBooleanTrue
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        switch status {
        case errSecSuccess:
            return item as? Data
        case errSecItemNotFound:
            return nil
        default:
            throw KeychainError.unexpectedStatus(status)
        }
    }

    /// Delete is a no-op when the item is absent.
    public func delete(key: String) throws {
        let query = baseQuery(account: key)
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    // String convenience helpers — most call sites store UTF-8 text.

    public func writeString(_ value: String, key: String) throws {
        guard let data = value.data(using: .utf8) else { throw KeychainError.encodingFailure }
        try write(key: key, data: data)
    }

    public func readString(key: String) throws -> String? {
        guard let data = try read(key: key) else { return nil }
        guard let s = String(data: data, encoding: .utf8) else { throw KeychainError.encodingFailure }
        return s
    }
}

/// Sendable storage seam. `SessionStore` and `DeviceIdProvider` consume
/// this protocol so tests can swap in `InMemoryKeychain` on hosts that
/// reject `SecItem*` (unsigned XCTest hosts, Linux). All methods are
/// `async throws` so a real Keychain implementation that hops to a
/// background queue can satisfy them without changing call sites.
public protocol KeychainStorage: Sendable {
    func readData(forKey key: String) async throws -> Data?
    func writeData(_ data: Data, forKey key: String) async throws
    func deleteData(forKey key: String) async throws
}

/// Adapter wrapping the synchronous `KeychainStore` so it can be handed to
/// any consumer that asks for a `KeychainStorage`. The wrapper does not
/// hop threads — `SecItem*` is fast and already thread-safe — but the
/// async signature lets the storage seam stay uniform.
public struct KeychainStorageAdapter: KeychainStorage {
    private let store: KeychainStore

    public init(_ store: KeychainStore) {
        self.store = store
    }

    public func readData(forKey key: String) async throws -> Data? {
        try store.read(key: key)
    }
    public func writeData(_ data: Data, forKey key: String) async throws {
        try store.write(key: key, data: data)
    }
    public func deleteData(forKey key: String) async throws {
        try store.delete(key: key)
    }
}

/// In-memory `KeychainStorage` for tests and previews. Backed by an actor
/// so reads and writes from arbitrary tasks stay consistent.
public actor InMemoryKeychain: KeychainStorage {
    private var items: [String: Data] = [:]

    public init() {}

    public func readData(forKey key: String) async throws -> Data? { items[key] }
    public func writeData(_ data: Data, forKey key: String) async throws { items[key] = data }
    public func deleteData(forKey key: String) async throws { items.removeValue(forKey: key) }
}
