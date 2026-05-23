import SwiftUI
import WorkCore
import WorkUI
import Observation

@Observable
@MainActor
public final class ConferencesViewModel {
    public private(set) var deadlines: [ConferenceDeadline] = []
    public private(set) var error: WorkError?
    public var showDismissed: Bool = false
    public var kindFilter: ConferenceDeadline.Kind? = nil

    private let repository: any ConferencesRepositoryProtocol
    private var streamTask: Task<Void, Never>?

    public init(repository: any ConferencesRepositoryProtocol) { self.repository = repository }

    public func start() {
        streamTask?.cancel()
        streamTask = Task { [repository] in
            for await ds in repository.stream() {
                await MainActor.run { self.deadlines = ds }
            }
        }
        Task { try? await repository.refresh() }
    }

    public func dismiss(_ id: ConferenceDeadline.ID) async { try? await repository.dismiss(id) }
    public func restore(_ id: ConferenceDeadline.ID) async { try? await repository.restore(id) }

    public var visible: [ConferenceDeadline] {
        deadlines
            .filter { showDismissed || !$0.dismissed }
            .filter { kindFilter == nil || $0.kind == kindFilter }
            .sorted { $0.deadline < $1.deadline }
    }
}

public struct ConferencesView: View {
    @State private var viewModel: ConferencesViewModel

    public init(viewModel: ConferencesViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                filterBar
                Divider().background(Theme.border)
                list
            }
        }
        .preferredColorScheme(.dark)
        .navigationTitle("Conferences")
        .navigationBarTitleDisplayMode(.inline)
        .task { viewModel.start() }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Toggle(isOn: $viewModel.showDismissed) {
                    Image(systemName: viewModel.showDismissed ? "eye" : "eye.slash")
                }
                .toggleStyle(.button)
                .tint(Theme.accent)
            }
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                SelectablePill(label: "All", isSelected: viewModel.kindFilter == nil) {
                    viewModel.kindFilter = nil
                }
                ForEach([ConferenceDeadline.Kind.cfp, .submission, .revision, .cameraReady, .registration], id: \.self) { k in
                    SelectablePill(label: k.label, isSelected: viewModel.kindFilter == k, tint: tint(k)) {
                        viewModel.kindFilter = (viewModel.kindFilter == k) ? nil : k
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    private var list: some View {
        List {
            ForEach(viewModel.visible) { deadline in
                ConferenceRow(deadline: deadline)
                    .listRowBackground(Theme.surface1)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        if deadline.dismissed {
                            Button { Task { await viewModel.restore(deadline.id) } } label: {
                                Label("Restore", systemImage: "arrow.uturn.left")
                            }.tint(Theme.accent)
                        } else {
                            Button(role: .destructive) {
                                Task { await viewModel.dismiss(deadline.id) }
                            } label: { Label("Dismiss", systemImage: "xmark") }
                        }
                    }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Theme.background)
    }

    private func tint(_ k: ConferenceDeadline.Kind) -> Color {
        switch k {
        case .cfp:          return Theme.cyan
        case .submission:   return Theme.warning
        case .revision:     return Theme.violet
        case .cameraReady:  return Theme.danger
        case .registration: return Theme.accent
        case .other:        return Theme.textMuted
        }
    }
}

struct ConferenceRow: View {
    let deadline: ConferenceDeadline

    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 4) {
                Text("\(max(deadline.daysUntil, 0))")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(deadline.daysUntil < 7 ? Theme.danger : Theme.textPrimary)
                Text("days")
                    .workUppercaseLabel(8, color: Theme.textFaint)
            }
            .frame(width: 56)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(deadline.conferenceCode)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    StatusPill(label: deadline.kind.label, tint: kindTint)
                }
                Text(deadline.conferenceName)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textMuted)
                    .lineLimit(1)
                HStack(spacing: 10) {
                    if let loc = deadline.location {
                        Label(loc, systemImage: "mappin.and.ellipse")
                            .font(.workMono(10))
                            .foregroundStyle(Theme.textFaint)
                    }
                    Spacer()
                    Text(deadline.deadline.formatted(date: .abbreviated, time: .omitted))
                        .font(.workMono(10))
                        .foregroundStyle(Theme.textFaint)
                }
            }
            .opacity(deadline.dismissed ? 0.45 : 1)
        }
        .padding(.vertical, 4)
    }

    private var kindTint: Color {
        switch deadline.kind {
        case .cfp:          return Theme.cyan
        case .submission:   return Theme.warning
        case .revision:     return Theme.violet
        case .cameraReady:  return Theme.danger
        case .registration: return Theme.accent
        case .other:        return Theme.textMuted
        }
    }
}

#Preview {
    NavigationStack {
        ConferencesView(viewModel: ConferencesViewModel(repository: PreviewConferencesRepository()))
    }
}
