import SwiftUI
import Models
import DesignSystem
/// Top-level work surfaces. Mirrors synapse-v2's WORK_GROUPS one-for-one.
public enum WorkSurface: String, Hashable, CaseIterable, Identifiable, Sendable {
    // SIGNAL
    case dashboard
    case timeline
    case people
    case load
    case digest
    case inbox
    case plan

    // EDITORIAL & SERVICE
    case reviews
    case automation
    case spotlight

    // RESEARCH
    case conferences
    case grants

    // STUDENTS
    case applicants

    // ADMIN
    case approvals
    case receipts
    case submissions

    // TOOLS
    case ask
    case cost
    case integrations
    case sequences
    case network
    case settings

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .dashboard:    return "Dashboard"
        case .timeline:     return "Timeline"
        case .people:       return "People"
        case .load:         return "Load"
        case .digest:       return "Digest"
        case .inbox:        return "Inbox"
        case .plan:         return "Plan"
        case .reviews:      return "Reviews"
        case .automation:   return "Automation"
        case .spotlight:    return "Spotlight"
        case .conferences:  return "Conferences"
        case .grants:       return "Grant Proposals"
        case .applicants:   return "Applicants"
        case .approvals:    return "Approvals"
        case .receipts:     return "Receipts"
        case .submissions:  return "Submissions"
        case .ask:          return "Ask AI"
        case .cost:         return "AI Cost"
        case .integrations: return "Integrations"
        case .sequences:    return "Sequences"
        case .network:      return "Network"
        case .settings:     return "Settings"
        }
    }

    public var systemImage: String {
        switch self {
        case .dashboard:    return "rectangle.3.group"
        case .timeline:     return "clock.arrow.circlepath"
        case .people:       return "person.2"
        case .load:         return "chart.bar.xaxis"
        case .digest:       return "newspaper"
        case .inbox:        return "tray"
        case .plan:         return "calendar.badge.clock"
        case .reviews:      return "doc.text.magnifyingglass"
        case .automation:   return "bolt.horizontal.circle"
        case .spotlight:    return "sparkles"
        case .conferences:  return "calendar"
        case .grants:       return "banknote"
        case .applicants:   return "graduationcap"
        case .approvals:    return "checkmark.seal"
        case .receipts:     return "doc.text"
        case .submissions:  return "tray.and.arrow.up"
        case .ask:          return "bubble.left.and.bubble.right"
        case .cost:         return "dollarsign.circle"
        case .integrations: return "link.circle"
        case .sequences:    return "envelope.arrow.triangle.branch"
        case .network:      return "circle.grid.hex"
        case .settings:     return "gearshape"
        }
    }

    public var group: SidebarGroup {
        switch self {
        case .dashboard, .timeline, .people, .load, .digest, .inbox, .plan:
            return .signal
        case .reviews, .automation, .spotlight:
            return .editorial
        case .conferences, .grants:
            return .research
        case .applicants:
            return .students
        case .approvals, .receipts, .submissions:
            return .admin
        case .ask, .cost, .integrations, .sequences, .network, .settings:
            return .tools
        }
    }
}

public enum SidebarGroup: String, CaseIterable, Sendable {
    case signal     = "SIGNAL"
    case editorial  = "EDITORIAL & SERVICE"
    case research   = "RESEARCH"
    case students   = "STUDENTS"
    case admin      = "ADMIN"
    case tools      = "TOOLS"
}

@MainActor
public final class WorkSurfaceFactory {
    public init() {}

    public lazy var spotlightVM: SpotlightViewModel = SpotlightViewModel(repository: PreviewSpotlightRepository())
    public lazy var approvalsVM: ApprovalsViewModel = ApprovalsViewModel(repository: PreviewApprovalsRepository())
    public lazy var inboxVM: InboxViewModel = InboxViewModel(repository: PreviewInboxRepository())
    public lazy var peopleVM: PeopleViewModel = PeopleViewModel(repository: PreviewPeopleRepository())
    public lazy var sequencesVM: SequencesViewModel = SequencesViewModel(repository: PreviewSequencesRepository())
    public lazy var timelineVM: TimelineViewModel = TimelineViewModel(repository: PreviewTimelineRepository())
    public lazy var reviewsVM: ReviewsViewModel = ReviewsViewModel(repository: PreviewReviewsRepository())
    public lazy var askVM: AskViewModel = AskViewModel(repository: PreviewAskRepository())
    public lazy var conferencesVM: ConferencesViewModel = ConferencesViewModel(repository: PreviewConferencesRepository())
    public lazy var costVM: CostViewModel = CostViewModel(repository: PreviewCostRepository())

    @ViewBuilder
    public func view(for surface: WorkSurface) -> some View {
        switch surface {
        case .dashboard:    TimelineView(viewModel: timelineVM)
        case .timeline:     TimelineView(viewModel: timelineVM)
        case .spotlight:    SpotlightView(viewModel: spotlightVM)
        case .approvals:    ApprovalsView(viewModel: approvalsVM)
        case .inbox:        InboxView(viewModel: inboxVM)
        case .people:       PeopleView(viewModel: peopleVM)
        case .sequences:    SequencesView(viewModel: sequencesVM)
        case .reviews:      ReviewsView(viewModel: reviewsVM)
        case .ask:          AskView(viewModel: askVM)
        case .conferences:  ConferencesView(viewModel: conferencesVM)
        case .cost:         CostView(viewModel: costVM)
        case .settings:     SettingsView()
        case .load:         RoutedStub(surface: .load, eta: "M3")
        case .digest:       RoutedStub(surface: .digest, eta: "M3")
        case .plan:         RoutedStub(surface: .plan, eta: "M6")
        case .automation:   RoutedStub(surface: .automation, eta: "M6")
        case .grants:       RoutedStub(surface: .grants, eta: "M5")
        case .applicants:   RoutedStub(surface: .applicants, eta: "M5")
        case .receipts:     RoutedStub(surface: .receipts, eta: "M2")
        case .submissions:  RoutedStub(surface: .submissions, eta: "M2")
        case .integrations: RoutedStub(surface: .integrations, eta: "M5")
        case .network:      RoutedStub(surface: .network, eta: "M4")
        }
    }
}

public struct RootShell: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var factory = WorkSurfaceFactory()
    @State private var heartbeat: DaemonHeartbeat? = DaemonHeartbeat(lastTick: Date().addingTimeInterval(-180))
    @State private var paletteShown: Bool = false

    public init() {}

    public var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                iPadShell(factory: factory, heartbeat: $heartbeat, paletteShown: $paletteShown)
            } else {
                iPhoneShell(factory: factory, heartbeat: $heartbeat, paletteShown: $paletteShown)
            }
        }
        .tint(Theme.accent)
        .sheet(isPresented: $paletteShown) {
            SearchPaletteView()
        }
    }
}

struct iPhoneShell: View {
    let factory: WorkSurfaceFactory
    @Binding var heartbeat: DaemonHeartbeat?
    @Binding var paletteShown: Bool
    @State private var selection: WorkSurface = .dashboard

    var body: some View {
        TabView(selection: $selection) {
            NavigationStack { factory.view(for: .dashboard) }
                .tabItem { Label("Dashboard", systemImage: WorkSurface.dashboard.systemImage) }
                .tag(WorkSurface.dashboard)

            NavigationStack { factory.view(for: .inbox) }
                .tabItem { Label("Inbox", systemImage: WorkSurface.inbox.systemImage) }
                .tag(WorkSurface.inbox)

            NavigationStack { factory.view(for: .reviews) }
                .tabItem { Label("Reviews", systemImage: WorkSurface.reviews.systemImage) }
                .tag(WorkSurface.reviews)

            NavigationStack { factory.view(for: .approvals) }
                .tabItem { Label("Approvals", systemImage: WorkSurface.approvals.systemImage) }
                .tag(WorkSurface.approvals)

            NavigationStack { MoreList(factory: factory) }
                .tabItem { Label("More", systemImage: "ellipsis.circle") }
                .tag(WorkSurface.settings)
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
    @Binding var paletteShown: Bool
    @State private var selection: WorkSurface? = .dashboard
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
                ForEach(SidebarGroup.allCases, id: \.self) { group in
                    let surfaces = WorkSurface.allCases.filter { $0.group == group }
                    if !surfaces.isEmpty {
                        Section {
                            ForEach(surfaces) { surface in
                                NavigationLink(value: surface) {
                                    Label(surface.label, systemImage: surface.systemImage)
                                        .foregroundStyle(Theme.textPrimary)
                                }
                                .listRowBackground(Theme.surface1)
                            }
                        } header: {
                            Text(group.rawValue)
                                .workUppercaseLabel(10, color: Theme.textFaint)
                        }
                    }
                }

                Section {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Theme.accent)
                            .frame(width: 6, height: 6)
                            .overlay(
                                Circle()
                                    .stroke(Theme.accent.opacity(0.5), lineWidth: 4)
                                    .blur(radius: 2)
                            )
                        Text("connected")
                            .workUppercaseLabel(9, color: Theme.textFaint)
                        Spacer()
                        Button {
                            paletteShown = true
                        } label: {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(Theme.textMuted)
                        }
                        .buttonStyle(.plain)
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
            .background(Theme.background)
        }
        .navigationTitle("Synapse Work")
    }
}

struct MoreList: View {
    let factory: WorkSurfaceFactory

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            List {
                ForEach(SidebarGroup.allCases, id: \.self) { group in
                    let surfaces = WorkSurface.allCases.filter {
                        $0.group == group &&
                        ![WorkSurface.dashboard, .inbox, .reviews, .approvals].contains($0)
                    }
                    if !surfaces.isEmpty {
                        Section {
                            ForEach(surfaces) { surface in
                                NavigationLink {
                                    factory.view(for: surface)
                                } label: {
                                    Label(surface.label, systemImage: surface.systemImage)
                                }
                                .listRowBackground(Theme.surface1)
                            }
                        } header: { WorkSectionHeader(group.rawValue) }
                    }
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
        .navigationTitle("More")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

struct RoutedStub: View {
    let surface: WorkSurface
    let eta: String

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 18) {
                Spacer()
                Image(systemName: surface.systemImage)
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(Theme.accent.opacity(0.7))
                Text(surface.label)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text("Coming in \(eta)")
                    .workUppercaseLabel(11, color: Theme.textMuted)
                Text("Surface scaffolded in the IA; client repo + view land in the listed milestone. Server data already flows on synapse-v2 — this is a UI-only gap.")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textFaint)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                Spacer()
                Spacer()
            }
        }
        .navigationTitle(surface.label)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

struct SearchPaletteView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    private let suggestions: [(label: String, systemImage: String, kind: String)] = [
        ("Spotlight: causal reasoning", "sparkles", "Spotlight pick"),
        ("Approval: Anthropic April", "checkmark.seal", "Approval"),
        ("Review: TOSEM-2025-1266", "doc.text.magnifyingglass", "Review"),
        ("Conference: ICSE 2026 CR", "calendar", "Deadline"),
        ("Person: Lin Tan", "person", "Contact"),
        ("Sequence: Mike Ernst", "envelope.arrow.triangle.branch", "Sequence"),
        ("Receipt: Notion Q2", "doc.text", "Receipt"),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                List {
                    ForEach(filtered, id: \.label) { item in
                        HStack(spacing: 10) {
                            Image(systemName: item.systemImage)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Theme.accent)
                                .frame(width: 22)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.label)
                                    .font(.system(size: 13))
                                    .foregroundStyle(Theme.textPrimary)
                                Text(item.kind)
                                    .workUppercaseLabel(9, color: Theme.textFaint)
                            }
                            Spacer()
                            Image(systemName: "arrow.right")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Theme.textFaint)
                        }
                        .listRowBackground(Theme.surface1)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Theme.background)
            }
            .navigationTitle("Search")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .searchable(text: $query, placement: .automatic)
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Theme.accent)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var filtered: [(label: String, systemImage: String, kind: String)] {
        guard !query.isEmpty else { return suggestions }
        let needle = query.lowercased()
        return suggestions.filter {
            $0.label.lowercased().contains(needle) ||
            $0.kind.lowercased().contains(needle)
        }
    }
}
