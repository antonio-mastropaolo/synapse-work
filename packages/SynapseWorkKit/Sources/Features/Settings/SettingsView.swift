import SwiftUI
import Models
import DesignSystem
import Auth

public struct SettingsView: View {

    /// Optional Auth coordinator. When non-nil the Account section
    /// renders a "Delete account" destructive row that calls the
    /// synapse-v2 `POST /api/account/delete` endpoint and then signs the
    /// user out locally. Snapshot previews leave this nil so the legacy
    /// reference images are unaffected.
    private let auth: AuthCoordinator?
    /// Live session store, observed so the Account section reflects
    /// signed-in identity and the Delete row hides when signed out.
    private let session: SessionStore?

    public init(auth: AuthCoordinator? = nil, session: SessionStore? = nil) {
        self.auth = auth
        self.session = session
    }

    @State private var showDeleteConfirm: Bool = false
    @State private var showDeleteFinalConfirm: Bool = false
    @State private var deleteError: String?

    public var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            List {
                Section {
                    if let userId = session?.userId {
                        SettingsRow(icon: "person.crop.circle.fill", label: "User", value: userId)
                    } else {
                        SettingsRow(icon: "person.crop.circle.fill", label: "Account", value: "Antonio Mastropaolo")
                    }
                    SettingsRow(icon: "at", label: "Email", value: "amastropaolo@wm.edu")
                    SettingsRow(icon: "building.2.fill", label: "Org", value: "William & Mary CS")
                } header: { WorkSectionHeader("IDENTITY") }
                .listRowBackground(Theme.surface1)

                Section {
                    SettingsRow(icon: "server.rack", label: "API base", value: "synapse-v2.local")
                    SettingsRow(icon: "antenna.radiowaves.left.and.right", label: "Daemon", value: "running")
                    SettingsRow(icon: "lock.shield", label: "Auth", value: "JWT · device-bound")
                } header: { WorkSectionHeader("BACKEND") }
                .listRowBackground(Theme.surface1)

                Section {
                    SettingsRow(icon: "sparkles", label: "Apple Intelligence", value: "M5")
                    SettingsRow(icon: "bell.badge.fill", label: "Push notifications", value: "M5")
                    SettingsRow(icon: "icloud.fill", label: "iCloud sync", value: "off")
                } header: { WorkSectionHeader("FEATURES") }
                .listRowBackground(Theme.surface1)

                Section {
                    SettingsRow(icon: "info.circle", label: "Build", value: "0.1.0 (M1)")
                    SettingsRow(icon: "doc.text", label: "Licenses", value: "Geist OFL · Apache")
                } header: { WorkSectionHeader("ABOUT") }
                .listRowBackground(Theme.surface1)

                if auth != nil, session?.isSignedIn == true {
                    Section {
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "trash.fill")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.red)
                                    .frame(width: 22)
                                Text("Delete account")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.red)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .frame(minHeight: 44)
                        }
                        .accessibilityIdentifier("settings.account.deleteAccountButton")
                        if let msg = deleteError {
                            Text(msg)
                                .font(.system(size: 11))
                                .foregroundStyle(.red)
                        }
                    } header: {
                        WorkSectionHeader("DANGER ZONE")
                    } footer: {
                        Text("Permanently deletes your Synapse Work account and removes data from this device. This cannot be undone.")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.textMuted)
                    }
                    .listRowBackground(Theme.surface1)
                }
            }
            #if os(iOS)
            .listStyle(.insetGrouped)
            #else
            .listStyle(.inset)
            #endif
            .scrollContentBackground(.hidden)
            .background(Theme.background)
        }
        .navigationTitle("Settings")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        // Two-step destructive confirmation: a primary dialog asks the
        // user to acknowledge what "delete" means, and a second
        // dialog asks them to really do it. Apple HIG: high-stakes
        // destructive actions should require explicit reaffirmation.
        .confirmationDialog(
            "Delete your Synapse Work account?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Continue", role: .destructive) {
                showDeleteFinalConfirm = true
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your account and on-device data will be removed. This cannot be undone.")
        }
        .confirmationDialog(
            "Are you absolutely sure?",
            isPresented: $showDeleteFinalConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete account permanently", role: .destructive) {
                Task { await performDelete() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Tap Delete to confirm. Your JWT will be revoked on the server and removed from this device.")
        }
    }

    private func performDelete() async {
        guard let auth else { return }
        deleteError = nil
        await auth.deleteAccount()
    }
}

private struct SettingsRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .frame(width: 22)
            Text(label).font(.system(size: 13)).foregroundStyle(Theme.textPrimary)
            Spacer()
            Text(value).font(.workMono(11)).foregroundStyle(Theme.textMuted)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    NavigationStack { SettingsView() }
}
