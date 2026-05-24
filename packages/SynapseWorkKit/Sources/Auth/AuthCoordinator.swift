import Foundation
import Models

/// Glue between the AuthenticationServices flow and the network contract.
/// Owns the `SignInWithAppleHandler`, the `AppleAuthAPI`, the
/// `DeviceIdProvider`, and the `SessionStore`. Callers invoke
/// `signIn(with:appBundleId:)` after the system sheet resolves and the
/// coordinator handles the rest end-to-end.
///
/// `@MainActor` because it touches the observable `SessionStore`.
@MainActor
public final class AuthCoordinator {

    private let api: AppleAuthAPI
    private let store: SessionStore
    private let handler: SignInWithAppleHandler
    private let deviceId: DeviceIdProvider

    public init(
        api: AppleAuthAPI,
        store: SessionStore,
        handler: SignInWithAppleHandler = SignInWithAppleHandler(),
        deviceId: DeviceIdProvider
    ) {
        self.api = api
        self.store = store
        self.handler = handler
        self.deviceId = deviceId
    }

    /// Hand a credential through the contract, persist the returned JWT
    /// in the SessionStore, and surface the live `Session`. Throws the
    /// underlying `AppleAuthAPIError` / `AppleSignInError` on failure so
    /// view code can branch on the typed reason.
    @discardableResult
    public func signIn(
        with credential: AppleCredentialLike,
        appBundleId: String
    ) async throws -> Session {
        let extracted = try handler.handle(credential)
        let request = AppleAuthRequest(
            identityToken: extracted.identityToken.base64EncodedString(),
            authorizationCode: extracted.authorizationCode?.base64EncodedString(),
            givenName: extracted.fullName?.givenName,
            familyName: extracted.fullName?.familyName,
            email: extracted.email,
            deviceId: await deviceId.current(),
            platform: ApplePlatform.current(),
            appBundleId: appBundleId
        )
        let response = try await api.signInWithApple(request)
        await store.setSession(jwt: response.jwt, expiresAt: response.expiresAt, userId: response.userId)
        return Session(userId: response.userId, jwt: response.jwt, expiresAt: response.expiresAt)
    }

    /// Apple Guideline 5.1.1(v): the app must let users delete the
    /// server-side account. Best-effort delete, then unconditionally
    /// clears local state so an offline user still ends up signed out.
    public func deleteAccount() async {
        if let jwt = await store.currentToken() {
            _ = try? await api.deleteAccount(jwt: jwt)
        }
        await store.signOut()
    }
}
