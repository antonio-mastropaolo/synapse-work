import SwiftUI
import WorkCore
import WorkUI
import WorkFeatures

@main
struct SynapseWorkApp: App {
    @State private var authState = AuthState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(authState)
                .preferredColorScheme(.dark)
                .tint(Theme.accent)
        }
    }
}

@Observable
@MainActor
final class AuthState {
    // M1: stubbed signed-in. Real SIWA flow wires up once /api/auth/apple is server-side.
    var isSignedIn: Bool = true
}

struct RootView: View {
    @Environment(AuthState.self) private var auth

    var body: some View {
        if auth.isSignedIn {
            RootShell()
        } else {
            SignInScreen()
        }
    }
}

struct SignInScreen: View {
    @Environment(AuthState.self) private var auth

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 24) {
                Text("SYNAPSE WORK")
                    .workUppercaseLabel(13, color: Theme.accent)
                Text("Sign in with Apple")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Button {
                    auth.isSignedIn = true
                } label: {
                    Text("Continue").frame(maxWidth: 280)
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.accent)
            }
        }
        .preferredColorScheme(.dark)
    }
}
