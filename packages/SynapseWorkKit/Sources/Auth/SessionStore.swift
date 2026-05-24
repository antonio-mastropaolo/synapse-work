import Foundation
import Observation
import Models

/// Holds the active `Session` (JWT + userId + expiresAt) and persists it
/// to the Keychain. `@Observable` so SwiftUI scenes can drive root-level
/// auth-gating off `isSignedIn`; `@MainActor` because the observable
/// surface is read from view code that already runs on main.
///
/// The store is the canonical source of truth for "am I signed in";
/// `APIClient` consults it via `currentToken()` on every request and
/// calls `signOut()` on a 401.
@MainActor
@Observable
public final class SessionStore {

    /// Account / key constants used inside the underlying Keychain
    /// item. `envelope` carries the JSON-encoded `Session` value.
    public static let defaultService = "tech.synapse.work.session"
    public static let envelopeKey = "session.envelope"

    public private(set) var jwt: String?
    public private(set) var expiresAt: Date?
    public private(set) var userId: String?

    /// Bootstrap state. The view layer renders a "loading" splash while
    /// `bootstrap()` is in flight so we don't briefly flash the sign-in
    /// screen for an already-authenticated user.
    public private(set) var didBootstrap: Bool = false

    private let storage: KeychainStorage

    public init(storage: KeychainStorage) {
        self.storage = storage
    }

    /// Production convenience. Wires the live Keychain with the shared
    /// access-group so the four Synapse binaries observe the same item.
    public static func live(
        service: String = SessionStore.defaultService,
        accessGroup: String? = KeychainStore.sharedAccessGroup
    ) -> SessionStore {
        let store = KeychainStore(
            service: service,
            accessibility: KeychainStore.defaultAccessibility,
            accessGroup: accessGroup
        )
        return SessionStore(storage: KeychainStorageAdapter(store))
    }

    /// Whether a non-expired session is currently held.
    public var isSignedIn: Bool {
        guard let expiresAt else { return false }
        return jwt != nil && expiresAt > Date()
    }

    /// Load the persisted session into memory. Call once at app launch
    /// before deciding which root view to render. Expired sessions are
    /// cleared so a stale envelope cannot keep the app in a half-signed-in
    /// state where the server would 401 every request.
    public func bootstrap() async {
        defer { didBootstrap = true }
        do {
            guard let data = try await storage.readData(forKey: Self.envelopeKey) else {
                return
            }
            let envelope = try Self.decoder().decode(Session.self, from: data)
            if envelope.expiresAt > Date() {
                self.jwt = envelope.jwt
                self.expiresAt = envelope.expiresAt
                self.userId = envelope.userId
            } else {
                // Expired — wipe so we don't keep handing 401s back.
                try? await storage.deleteData(forKey: Self.envelopeKey)
            }
        } catch {
            // Corrupt or unreadable envelope: clear and continue signed-out.
            try? await storage.deleteData(forKey: Self.envelopeKey)
        }
    }

    public func setSession(jwt: String, expiresAt: Date, userId: String) async {
        let session = Session(userId: userId, jwt: jwt, expiresAt: expiresAt)
        do {
            let data = try Self.encoder().encode(session)
            try await storage.writeData(data, forKey: Self.envelopeKey)
            self.jwt = jwt
            self.expiresAt = expiresAt
            self.userId = userId
        } catch {
            // Persist failed: keep in-memory state nil so the next launch
            // doesn't observe a "half-signed-in" condition where the
            // envelope is stale but the live state thinks we're authed.
            self.jwt = nil
            self.expiresAt = nil
            self.userId = nil
            try? await storage.deleteData(forKey: Self.envelopeKey)
        }
    }

    public func signOut() async {
        try? await storage.deleteData(forKey: Self.envelopeKey)
        self.jwt = nil
        self.expiresAt = nil
        self.userId = nil
    }

    /// Returns the live token, or nil if the session is expired or absent.
    /// `APIClient` calls this on every request.
    public func currentToken() async -> String? {
        guard let jwt, let expiresAt, expiresAt > Date() else { return nil }
        return jwt
    }

    // MARK: - Coders

    private static func encoder() -> JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }

    private static func decoder() -> JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .custom { c in
            let v = try c.singleValueContainer()
            let raw = try v.decode(String.self)
            let withFrac = ISO8601DateFormatter()
            withFrac.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let parsed = withFrac.date(from: raw) { return parsed }
            let plain = ISO8601DateFormatter()
            plain.formatOptions = [.withInternetDateTime]
            if let parsed = plain.date(from: raw) { return parsed }
            throw DecodingError.dataCorruptedError(
                in: v,
                debugDescription: "Unparseable ISO-8601 date: \(raw)"
            )
        }
        return d
    }
}
