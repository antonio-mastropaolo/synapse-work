import SwiftUI
import WorkCore
import WorkUI

/// Top-level work surfaces that show up in both the iPhone tab bar and the iPad sidebar.
public enum WorkSurface: String, Hashable, CaseIterable, Identifiable, Sendable {
    case spotlight, approvals, inbox, people, sequences, settings

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .spotlight: return "Spotlight"
        case .approvals: return "Approvals"
        case .inbox:     return "Inbox"
        case .people:    return "People"
        case .sequences: return "Sequences"
        case .settings:  return "Settings"
        }
    }

    public var systemImage: String {
        switch self {
        case .spotlight: return "sparkles"
        case .approvals: return "checkmark.seal"
        case .inbox:     return "tray"
        case .people:    return "person.2"
        case .sequences: return "envelope.arrow.triangle.branch"
        case .settings:  return "gearshape"
        }
    }

    public var group: String {
        switch self {
        case .spotlight, .inbox:           return "SIGNAL"
        case .approvals, .sequences:       return "ADMIN"
        case .people:                      return "EDITORIAL"
        case .settings:                    return "TOOLS"
        }
    }
}

@MainActor
public final class WorkSurfaceFactory {
    public init() {}

    public lazy var spotlightVM: SpotlightViewModel = SpotlightViewModel(repository: PreviewSpotlightRepository())
    public lazy var approvalsVM: ApprovalsViewModel = ApprovalsViewModel(repository: PreviewApprovalsRepository())
    public lazy var inboxVM: InboxViewModel = InboxViewModel(repository: PreviewInboxRepository())
    public lazy var peopleVM: PeopleViewModel = PeopleViewModel(repository: PreviewPeopleRepository())
    public lazy var sequencesVM: SequencesViewModel = SequencesViewModel(repository: PreviewSequencesRepository())

    @ViewBuilder
    public func view(for surface: WorkSurface) -> some View {
        switch surface {
        case .spotlight: SpotlightView(viewModel: spotlightVM)
        case .approvals: ApprovalsView(viewModel: approvalsVM)
        case .inbox:     InboxView(viewModel: inboxVM)
        case .people:    PeopleView(viewModel: peopleVM)
        case .sequences: SequencesView(viewModel: sequencesVM)
        case .settings:  SettingsView()
        }
    }
}

public struct RootShell: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var factory = WorkSurfaceFactory()
    @State private var heartbeat: DaemonHeartbeat? = DaemonHeartbeat(lastTick: Date().addingTimeInterval(-180))

    public init() {}

    public var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                iPadShell(factory: factory, heartbeat: $heartbeat)
            } else {
                iPhoneShell(factory: factory, heartbeat: $heartbeat)
            }
        }
        .tint(Theme.accent)
    }
}

struct iPhoneShell: View {
    let factory: WorkSurfaceFactory
    @Binding var heartbeat: DaemonHeartbeat?
    @State private var selection: WorkSurface = .spotlight

    var body: some View {
        TabView(selection: $selection) {
            NavigationStack { factory.view(for: .spotlight) }
                .tabItem { Label(WorkSurface.spotlight.label, systemImage: WorkSurface.spotlight.systemImage) }
                .tag(WorkSurface.spotlight)

            NavigationStack { factory.view(for: .approvals) }
                .tabItem { Label(WorkSurface.approvals.label, systemImage: WorkSurface.approvals.systemImage) }
                .tag(WorkSurface.approvals)

            NavigationStack { factory.view(for: .inbox) }
                .tabItem { Label(WorkSurface.inbox.label, systemImage: WorkSurface.inbox.systemImage) }
                .tag(WorkSurface.inbox)

            NavigationStack { factory.view(for: .people) }
                .tabItem { Label(WorkSurface.people.label, systemImage: WorkSurface.people.systemImage) }
                .tag(WorkSurface.people)

            NavigationStack { MoreList(factory: factory) }
                .tabItem { Label("More", systemImage: "ellipsis.circle") }
                .tag(WorkSurface.sequences)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            DaemonStalenessBanner(heartbeat: heartbeat) {
                heartbeat = DaemonHeartbeat(lastTick: Date())
            }
        }
    }
}

struct iPadShell: View {
    let factory: WorkSurfaceFactory
    @Binding var heartbeat: DaemonHeartbeat?
    @State private var selection: WorkSurface? = .spotlight
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebar
        } detail: {
            NavigationStack {
                if let selection {
                    factory.view(for: selection)
                } else {
                    ContentUnavailableView("Select a surface", systemImage: "sidebar.left")
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
        .safeAreaInset(edge: .top, spacing: 0) {
            DaemonStalenessBanner(heartbeat: heartbeat) {
                heartbeat = DaemonHeartbeat(lastTick: Date())
            }
        }
    }

    private var sidebar: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            List(selection: $selection) {
                ForEach(grouped, id: \.group) { entry in
                    Section {
                        ForEach(entry.surfaces) { surface in
                            NavigationLink(value: surface) {
                                Label(surface.label, systemImage: surface.systemImage)
                                    .foregroundStyle(Theme.textPrimary)
                            }
                            .listRowBackground(Theme.surface1)
                        }
                    } header: {
                        Text(entry.group)
                            .workUppercaseLabel(10, color: Theme.textFaint)
                    }
                }
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
            .background(Theme.background)
        }
        .navigationTitle("Synapse Work")
    }

    private var grouped: [(group: String, surfaces: [WorkSurface])] {
        let dict = Dictionary(grouping: WorkSurface.allCases, by: { $0.group })
        let order = ["SIGNAL", "ADMIN", "EDITORIAL", "TOOLS"]
        return order.compactMap { g in
            guard let surfaces = dict[g] else { return nil }
            return (group: g, surfaces: surfaces)
        }
    }
}

struct MoreList: View {
    let factory: WorkSurfaceFactory

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            List {
                Section {
                    NavigationLink {
                        factory.view(for: .sequences)
                    } label: {
                        Label(WorkSurface.sequences.label, systemImage: WorkSurface.sequences.systemImage)
                    }
                    .listRowBackground(Theme.surface1)
                } header: { WorkSectionHeader("ADMIN") }

                Section {
                    NavigationLink {
                        factory.view(for: .settings)
                    } label: {
                        Label(WorkSurface.settings.label, systemImage: WorkSurface.settings.systemImage)
                    }
                    .listRowBackground(Theme.surface1)
                } header: { WorkSectionHeader("TOOLS") }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Theme.background)
        }
        .navigationTitle("More")
        .navigationBarTitleDisplayMode(.inline)
    }
}
