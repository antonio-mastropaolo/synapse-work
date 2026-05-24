import Foundation

/// Server-issued session. `jwt` is the bearer presented to the API on
/// every request. The new synapse-v2 contract is single-token — there is
/// no refresh token, just an `expiresAt` after which the client must
/// re-run Sign-in-with-Apple.
///
/// Stored in the Keychain by `SessionStore`; only `userId` and `expiresAt`
/// are safe to project into in-memory state.
public struct Session: Codable, Sendable, Equatable {
    public let userId: String
    public let jwt: String
    public let expiresAt: Date

    public init(userId: String, jwt: String, expiresAt: Date) {
        self.userId = userId
        self.jwt = jwt
        self.expiresAt = expiresAt
    }
}
