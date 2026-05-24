#if os(macOS)
import SwiftUI
import Auth
import DesignSystem
import Models

// MARK: - Focused-value plumbing

/// `@FocusedValue` lets the app-level `.commands { }` block reach into
/// the active window's `RootShellMac` to mutate selection / sidebar
/// visibility without us having to hoist state up into the `App`
/// struct. This is the canonical Mac pattern — the alternative
/// (NotificationCenter) leaks across windows and is a pain to test.
public struct MacShellActionsValue: Sendable {
    public var selectSurface: @MainActor (WorkSurface) -> Void
    public var togglePalette: @MainActor () -> Void
    public var toggleSidebar: @MainActor () -> Void

    public init(
        selectSurface: @escaping @MainActor (WorkSurface) -> Void,
        togglePalette: @escaping @MainActor () -> Void,
        toggleSidebar: @escaping @MainActor () -> Void
    ) {
        self.selectSurface = selectSurface
        self.togglePalette = togglePalette
        self.toggleSidebar = toggleSidebar
    }
}

public struct MacShellActionsKey: FocusedValueKey {
    public typealias Value = MacShellActionsValue
}

public extension FocusedValues {
    var macShellActions: MacShellActionsValue? {
        get { self[MacShellActionsKey.self] }
        set { self[MacShellActionsKey.self] = newValue }
    }
}

// MARK: - Shell

/// macOS-native shell. Distinct from `RootShell` (which serves
/// iPhone + iPad). Three-column NavigationSplitView, unified
/// toolbar with primary actions, dock-style status-bar
/// chrome at the sidebar foot, and `@SceneStorage` for window-
/// restoration of the selected surface and sidebar visibility.
public struct RootShellMac: View {
    @Environment(SessionStore.self) private var session

    @SceneStorage("synapse.work.mac.selectedSurface") private var storedSurfaceRaw: String = WorkSurface.dashboard.rawValue
    @SceneStorage("synapse.work.mac.sidebarVisibility") private var storedSidebarRaw: Int = 0  // 0=all, 1=detail

    @State private var factory = WorkSurfaceFactory()
    @State private var heartbeat: DaemonHeartbeat? = DaemonHeartbeat(lastTick: Date().addingTimeInterval(-180))
    @State private var paletteShown: Bool = false
    @State private var selection: WorkSurface = .dashboard
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var searchQuery: String = ""

    public init() {}

    public var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebar
                .navigationSplitViewColumnWidth(min: 220, ideal: 248, max: 320)
        } detail: {
            detail
                .navigationSplitViewColumnWidth(min: 600, ideal: 880)
        }
        .navigationSplitViewStyle(.balanced)
        .navigationTitle(selection.label)
        .toolbar { toolbarContent }
        .tint(Theme.accent)
        .background(Theme.background)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $paletteShown) {
            CommandPalette { surface in
                selection = surface
            }
        }
        .focusedSceneValue(\.macShellActions, MacShellActionsValue(
            selectSurface: { selection = $0 },
            togglePalette: { paletteShown.toggle() },
            toggleSidebar: { toggleSidebar() }
        ))
        .onAppear { restoreScene() }
        .onChange(of: selection) { _, new in storedSurfaceRaw = new.rawValue }
        .onChange(of: columnVisibility) { _, new in
            storedSidebarRaw = (new == .detailOnly) ? 1 : 0
        }
    }

    // MARK: Sidebar

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
                            }
                        } header: {
                            Text(group.rawValue)
                                .workUppercaseLabel(10, color: Theme.textTertiary)
                                .padding(.top, 4)
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .safeAreaInset(edge: .bottom) {
                sidebarFooter
            }
        }
    }

    private var sidebarFooter: some View {
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
                HStack(spacing: 4) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 10, weight: .bold))
                    Text("⌘K")
                        .font(.workMono(9))
                }
                .foregroundStyle(Theme.textMuted)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Theme.surface1, in: Capsule())
            }
            .buttonStyle(.plain)
            .help("Quick switcher (⌘K)")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.thinMaterial)
        .overlay(
            Rectangle().fill(Theme.border).frame(height: 0.5),
            alignment: .top
        )
    }

    // MARK: Detail

    private var detail: some View {
        ZStack(alignment: .top) {
            Theme.background.ignoresSafeArea()
            NavigationStack {
                factory.view(for: selection)
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                DaemonStalenessBanner(heartbeat: heartbeat) {
                    heartbeat = DaemonHeartbeat(lastTick: Date())
                }
            }
        }
    }

    // MARK: Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigation) {
            Button {
                toggleSidebar()
            } label: {
                Image(systemName: "sidebar.left")
            }
            .help("Toggle Sidebar (⌥⌘S)")
        }

        ToolbarItemGroup(placement: .primaryAction) {
            // Search field — opens the palette on submit. Acts as the
            // toolbar-resident counterpart to ⌘K so power users get
            // both a discoverable surface and a keyboard path.
            TextField("Search…", text: $searchQuery)
                .textFieldStyle(.roundedBorder)
                .frame(minWidth: 180, maxWidth: 240)
                .onSubmit {
                    paletteShown = true
                }

            Button {
                paletteShown = true
            } label: {
                Image(systemName: "command")
            }
            .help("Quick Switcher (⌘K)")

            Button {
                // Heartbeat refresh is the closest analog to "reload"
                // we have right now — wires into the same path the
                // staleness banner uses.
                heartbeat = DaemonHeartbeat(lastTick: Date())
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .help("Refresh")

            identityMenu
        }
    }

    private var identityMenu: some View {
        Menu {
            Text(identityLabel)
                .font(.system(size: 12))
            Divider()
            Button("Settings…") { selection = .settings }
            Button("Delete Account…", role: .destructive) {
                // Wired to surface — the actual delete flow lives in
                // Settings; we do NOT inline a destructive RPC here.
                selection = .settings
            }
            Divider()
            Button("Sign Out") {
                Task { await session.signOut() }
            }
        } label: {
            Image(systemName: "person.circle")
        }
        .menuStyle(.borderlessButton)
        .help(identityLabel)
    }

    private var identityLabel: String {
        if let id = session.userId, !id.isEmpty {
            // userIds are sub-claims, not human names — show a
            // short tail so the menu doesn't get a 40-char string.
            let tail = id.suffix(8)
            return "Account · …\(tail)"
        }
        return "Account"
    }

    // MARK: Helpers

    private func toggleSidebar() {
        switch columnVisibility {
        case .detailOnly: columnVisibility = .all
        default:          columnVisibility = .detailOnly
        }
    }

    private func restoreScene() {
        if let restored = WorkSurface(rawValue: storedSurfaceRaw) {
            selection = restored
        }
        columnVisibility = (storedSidebarRaw == 1) ? .detailOnly : .all
    }
}

// MARK: - Command-menu helpers

/// Convenience used by the App-level `.commands` block. Reads the
/// `macShellActions` focused value and dispatches against it.
public struct MacSurfacesCommandMenu: Commands {
    @FocusedValue(\.macShellActions) private var actions

    public init() {}

    public var body: some Commands {
        CommandMenu("Surfaces") {
            Button("Dashboard") { actions?.selectSurface(.dashboard) }
                .keyboardShortcut("1", modifiers: [.command])
            Button("Inbox") { actions?.selectSurface(.inbox) }
                .keyboardShortcut("2", modifiers: [.command])
            Button("Approvals") { actions?.selectSurface(.approvals) }
                .keyboardShortcut("3", modifiers: [.command])
            Button("Spotlight") { actions?.selectSurface(.spotlight) }
                .keyboardShortcut("4", modifiers: [.command])
            Button("People") { actions?.selectSurface(.people) }
                .keyboardShortcut("5", modifiers: [.command])
            Divider()
            Button("Open Quick Switcher…") { actions?.togglePalette() }
                .keyboardShortcut("k", modifiers: [.command])
        }
    }
}

public struct MacSidebarCommands: Commands {
    @FocusedValue(\.macShellActions) private var actions

    public init() {}

    public var body: some Commands {
        CommandGroup(after: .windowSize) {
            Button("Toggle Sidebar") {
                actions?.toggleSidebar()
            }
            .keyboardShortcut("s", modifiers: [.command, .option])
        }
    }
}

#endif
