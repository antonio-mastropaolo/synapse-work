import SwiftUI
import Models
import DesignSystem
import Features
import Auth

#if canImport(AuthenticationServices)
import AuthenticationServices
#endif

@main
struct SynapseWorkMacApp: App {
    @State private var session = SessionStore.live()
    @State private var auth: AuthCoordinator = SynapseWorkMacApp.makeCoordinator(session: nil)

    var body: some Scene {
        WindowGroup {
            RootView(session: session, auth: auth)
                .environment(session)
                .preferredColorScheme(.dark)
                .tint(Theme.accent)
                .frame(minWidth: 1100, minHeight: 720)
                .task {
                    await session.bootstrap()
                    auth = SynapseWorkMacApp.makeCoordinator(session: session)
                }
        }
        .windowToolbarStyle(.unifiedCompact)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) {}
            MacSurfacesCommandMenu()
            MacSidebarCommands()
        }
    }

    private static func makeCoordinator(session: SessionStore?) -> AuthCoordinator {
        let baseURL = SynapseWorkMacApp.resolveBaseURL()
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
        return URL(string: "http://localhost:3000/") ?? URL(fileURLWithPath: "/")
    }
}

struct RootView: View {
    let session: SessionStore
    let auth: AuthCoordinator

    var body: some View {
        if session.isSignedIn {
            #if os(macOS)
            RootShellMac()
            #else
            RootShell()
            #endif
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
                    appBundleId: Bundle.main.bundleIdentifier ?? "tech.synapse.work.mac"
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
