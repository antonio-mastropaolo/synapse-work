import Foundation

#if canImport(AuthenticationServices)
import AuthenticationServices
#endif
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Test-shaped seam over `ASAuthorizationAppleIDCredential`. We only need the
/// four fields the server cares about; modeling them as a protocol means
/// tests don't need to fabricate a real `ASAuthorizationAppleIDCredential`
/// (which can't be safely instantiated outside the AuthorizationController
/// flow).
public protocol AppleCredentialLike {
    var user: String { get }
    var identityToken: Data? { get }
    var authorizationCode: Data? { get }
    var email: String? { get }
    var fullName: PersonNameComponents? { get }
}

#if canImport(AuthenticationServices)
extension ASAuthorizationAppleIDCredential: AppleCredentialLike {}
#endif

public struct AppleSignInResult: Sendable, Equatable {
    public let userId: String
    public let identityToken: Data
    public let authorizationCode: Data?
    public let email: String?
    public let fullName: PersonNameComponents?

    public init(
        userId: String,
        identityToken: Data,
        authorizationCode: Data?,
        email: String?,
        fullName: PersonNameComponents?
    ) {
        self.userId = userId
        self.identityToken = identityToken
        self.authorizationCode = authorizationCode
        self.email = email
        self.fullName = fullName
    }
}

public enum AppleSignInError: Error, Equatable, Sendable {
    case missingIdentityToken
    /// Returned by the coordinator when AuthenticationServices reports a
    /// user cancellation. View code surfaces a quiet "try again" rather
    /// than an error toast.
    case cancelled(String)
    case unknown(String)
}

/// Pure value-shaper. Validates the credential and projects it into an
/// `AppleSignInResult`. The live coordinator below drives the
/// AuthenticationServices flow and feeds the credential through this
/// handler.
public struct SignInWithAppleHandler: Sendable {
    public init() {}

    public func handle(_ credential: AppleCredentialLike) throws -> AppleSignInResult {
        guard let token = credential.identityToken else {
            throw AppleSignInError.missingIdentityToken
        }
        return AppleSignInResult(
            userId: credential.user,
            identityToken: token,
            authorizationCode: credential.authorizationCode,
            email: credential.email,
            fullName: credential.fullName
        )
    }
}

#if canImport(AuthenticationServices)

/// Live Sign-in-with-Apple driver. Wraps `ASAuthorizationController` in a
/// Swift Concurrency continuation so view-model code can
/// `await coordinator.signIn()` without exposing AS delegates.
///
/// `@MainActor` because every AS call must happen on the main thread.
@MainActor
public final class SignInWithAppleCoordinator: NSObject,
    ASAuthorizationControllerDelegate,
    ASAuthorizationControllerPresentationContextProviding {

    private let handler: SignInWithAppleHandler
    private var continuation: CheckedContinuation<AppleSignInResult, Error>?

    public init(handler: SignInWithAppleHandler = SignInWithAppleHandler()) {
        self.handler = handler
    }

    public func signIn() async throws -> AppleSignInResult {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self

        return try await withCheckedThrowingContinuation { cont in
            self.continuation = cont
            controller.performRequests()
        }
    }

    // MARK: - ASAuthorizationControllerDelegate

    public func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        defer { continuation = nil }
        guard let cred = authorization.credential as? ASAuthorizationAppleIDCredential else {
            continuation?.resume(throwing: AppleSignInError.missingIdentityToken)
            return
        }
        do {
            let result = try handler.handle(cred)
            continuation?.resume(returning: result)
        } catch {
            continuation?.resume(throwing: error)
        }
    }

    public func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        defer { continuation = nil }
        if let asError = error as? ASAuthorizationError {
            switch asError.code {
            case .canceled:
                continuation?.resume(throwing: AppleSignInError.cancelled(asError.localizedDescription))
            default:
                continuation?.resume(throwing: AppleSignInError.unknown(asError.localizedDescription))
            }
        } else {
            continuation?.resume(throwing: AppleSignInError.unknown(error.localizedDescription))
        }
    }

    // MARK: - ASAuthorizationControllerPresentationContextProviding

    public func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        #if canImport(UIKit)
        if let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
           let window = scene.windows.first(where: { $0.isKeyWindow }) ?? scene.windows.first {
            return window
        }
        return ASPresentationAnchor()
        #elseif canImport(AppKit)
        return NSApplication.shared.keyWindow ?? NSApplication.shared.windows.first ?? ASPresentationAnchor()
        #else
        return ASPresentationAnchor()
        #endif
    }
}

#endif
