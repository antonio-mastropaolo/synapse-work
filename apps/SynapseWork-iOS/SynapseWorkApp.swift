import SwiftUI
import Models
import DesignSystem
import Features
import Auth

#if canImport(AuthenticationServices)
import AuthenticationServices
#endif

@main
struct SynapseWorkApp: App {
    /// Live session. Created once at app launch; `bootstrap()` rehydrates
    /// the JWT envelope from the shared `tech.synapse.shared` keychain
    /// group before the first frame so a previously signed-in user does
    /// not flash the sign-in screen.
    @State private var session = SessionStore.live()
    /// Auth coordinator. Wires the AuthenticationServices flow into
    /// `POST /api/auth/apple` and persists the returned JWT via
    /// `SessionStore`. The base URL is read from the bundled
    /// `SYNAPSE_API_BASE_URL` Info.plist entry — owned by the
    /// entitlements / Info.plist agent; we read it and fall back to
    /// localhost so the unsigned development build still launches.
    @State private var auth: AuthCoordinator = SynapseWorkApp.makeCoordinator(session: nil)

    var body: some Scene {
        WindowGroup {
            RootView(session: session, auth: auth)
                .environment(session)
                .preferredColorScheme(.dark)
                .tint(Theme.accent)
                .task {
                    await session.bootstrap()
                    // Rebuild the coordinator once the live session is
                    // bound; SwiftUI keeps the `@State` reference but the
                    // coordinator needs a reference to `session` for the
                    // delete-account path.
                    auth = SynapseWorkApp.makeCoordinator(session: session)
                }
        }
    }

    private static func makeCoordinator(session: SessionStore?) -> AuthCoordinator {
        let baseURL = SynapseWorkApp.resolveBaseURL()
        let api = LiveAppleAuthAPI(baseURL: baseURL)
        let deviceId = DeviceIdProvider.live()
        let store = session ?? SessionStore.live()
        return AuthCoordinator(api: api, store: store, deviceId: deviceId)
    }

    private static func resolveBaseURL() -> URL {
        if let raw = Bundle.main.object(forInfoDictionaryKey: "SYNAPSE_API_BASE_URL") as? String,
           let url = URL(string: raw) {
            return url
        }
        // Documented fallback for unsigned dev builds.
        return URL(string: "http://localhost:3000/") ?? URL(fileURLWithPath: "/")
    }
}

struct RootView: View {
    let session: SessionStore
    let auth: AuthCoordinator

    var body: some View {
        if session.isSignedIn {
            RootShell()
        } else {
            SignInScreen(session: session, auth: auth)
        }
    }
}

struct SignInScreen: View {
    let session: SessionStore
    let auth: AuthCoordinator

    @State private var errorMessage: String?
    @State private var isSigningIn: Bool = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 24) {
                Text("SYNAPSE WORK")
                    .workUppercaseLabel(13, color: Theme.accent)
                Text("Sign in with Apple")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                #if canImport(AuthenticationServices)
                SignInWithAppleButton(
                    onRequest: { request in
                        request.requestedScopes = [.fullName, .email]
                    },
                    onCompletion: { result in
                        Task { await handle(result) }
                    }
                )
                .signInWithAppleButtonStyle(.white)
                .frame(maxWidth: 280, minHeight: 48)
                #else
                Button("Sign in with Apple") {}
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.accent)
                #endif
                if isSigningIn {
                    ProgressView()
                        .progressViewStyle(.circular)
                }
                if let msg = errorMessage {
                    Text(msg)
                        .font(.system(size: 11))
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    #if canImport(AuthenticationServices)
    @MainActor
    private func handle(_ result: Result<ASAuthorization, Error>) async {
        isSigningIn = true
        defer { isSigningIn = false }
        switch result {
        case .success(let authorization):
            guard let cred = authorization.credential as? ASAuthorizationAppleIDCredential else {
                errorMessage = "Apple did not return a usable credential."
                return
            }
            do {
                _ = try await auth.signIn(
                    with: cred,
                    appBundleId: Bundle.main.bundleIdentifier ?? "tech.synapse.work.ios"
                )
                errorMessage = nil
            } catch let signInError as AppleSignInError {
                if case .cancelled = signInError { errorMessage = nil; return }
                errorMessage = String(describing: signInError)
            } catch let apiError as AppleAuthAPIError {
                errorMessage = String(describing: apiError)
            } catch {
                errorMessage = error.localizedDescription
            }
        case .failure(let error):
            if let asError = error as? ASAuthorizationError, asError.code == .canceled {
                errorMessage = nil
            } else {
                errorMessage = error.localizedDescription
            }
        }
    }
    #endif
}
