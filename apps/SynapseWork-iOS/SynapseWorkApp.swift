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
    var isSignedIn: Bool = true  // M1: stubbed signed-in. SIWA wiring lands once /api/auth/apple is server-side.
}

struct RootView: View {
    @Environment(AuthState.self) private var auth

    var body: some View {
        if auth.isSignedIn {
            MainTabs()
        } else {
            SignInScreen()
        }
    }
}

struct MainTabs: View {
    var body: some View {
        TabView {
            NavigationStack {
                SpotlightView(viewModel: SpotlightViewModel(repository: PreviewSpotlightRepository()))
            }
            .tabItem { Label("Spotlight", systemImage: "sparkles") }

            NavigationStack { PlaceholderScreen(title: "Approvals", systemImage: "checkmark.seal") }
                .tabItem { Label("Approvals", systemImage: "checkmark.seal") }

            NavigationStack { PlaceholderScreen(title: "Inbox", systemImage: "tray") }
                .tabItem { Label("Inbox", systemImage: "tray") }

            NavigationStack { PlaceholderScreen(title: "People", systemImage: "person.2") }
                .tabItem { Label("People", systemImage: "person.2") }

            NavigationStack { PlaceholderScreen(title: "More", systemImage: "ellipsis.circle") }
                .tabItem { Label("More", systemImage: "ellipsis.circle") }
        }
    }
}

struct PlaceholderScreen: View {
    let title: String
    let systemImage: String

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ContentUnavailableView(
                title,
                systemImage: systemImage,
                description: Text("Coming in a later milestone.")
            )
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
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
                    // M1 stub. Real SIWA + /api/auth/apple exchange lands when the
                    // server gap is in place. Flipping this in code is intentional
                    // until then so the rest of the UI is reachable.
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
