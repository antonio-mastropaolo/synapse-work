import Foundation

/// Stable per-device identifier persisted via `KeychainStorage`. The
/// synapse-v2 auth contract requires a `deviceId` on every
/// Sign-in-with-Apple exchange so the server can scope a session to a
/// single device.
///
/// Generated lazily on first read and cached. When all four Synapse
/// binaries share a `keychain-access-groups` entitlement
/// (`tech.synapse.shared`) the same id is observed across life-iOS,
/// life-mac, work-iOS, and work-mac on the same physical device.
public actor DeviceIdProvider {

    public static let defaultKey = "deviceId"
    public static let defaultService = "tech.synapse.device"

    private let storage: KeychainStorage
    private let key: String
    private var cached: String?

    public init(
        storage: KeychainStorage,
        key: String = DeviceIdProvider.defaultKey
    ) {
        self.storage = storage
        self.key = key
    }

    /// Convenience for production wiring: hands the live Keychain through
    /// the storage adapter with the shared access-group set.
    public static func live(
        service: String = DeviceIdProvider.defaultService,
        accessGroup: String? = KeychainStore.sharedAccessGroup
    ) -> DeviceIdProvider {
        let store = KeychainStore(
            service: service,
            accessibility: KeychainStore.defaultAccessibility,
            accessGroup: accessGroup
        )
        return DeviceIdProvider(storage: KeychainStorageAdapter(store))
    }

    /// Returns the persisted id, minting and storing a fresh UUID the
    /// first time. A failed persist degrades silently to a process-local
    /// UUID — the caller always gets a non-empty value.
    public func current() async -> String {
        if let cached { return cached }
        do {
            if let data = try await storage.readData(forKey: key),
               let s = String(data: data, encoding: .utf8),
               !s.isEmpty {
                cached = s
                return s
            }
        } catch {
            // Fall through to mint + best-effort persist.
        }
        let fresh = UUID().uuidString
        if let data = fresh.data(using: .utf8) {
            try? await storage.writeData(data, forKey: key)
        }
        cached = fresh
        return fresh
    }
}
