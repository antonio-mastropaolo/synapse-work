import SwiftUI
import Models
import DesignSystem
public struct SettingsView: View {
    public init() {}

    public var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            List {
                Section {
                    SettingsRow(icon: "person.crop.circle.fill", label: "Account", value: "Antonio Mastropaolo")
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
