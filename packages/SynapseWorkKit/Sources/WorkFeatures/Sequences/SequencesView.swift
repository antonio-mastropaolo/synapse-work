import SwiftUI
import WorkCore
import WorkUI

public struct SequencesView: View {
    @State private var viewModel: SequencesViewModel

    public init(viewModel: SequencesViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                kpiStrip
                statusBar
                Divider().background(Theme.border)
                list
            }
        }
        .preferredColorScheme(.dark)
        .navigationTitle("Sequences")
        .navigationBarTitleDisplayMode(.inline)
        .task { viewModel.start() }
        .refreshable { await viewModel.refresh() }
    }

    private var kpiStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                KPITile(label: "Active", value: "\(viewModel.activeCount)", accent: Theme.accent)
                KPITile(
                    label: "Replied",
                    value: "\(viewModel.repliedCount)",
                    trend: .up("\(Int(viewModel.replyRate * 100))% rate"),
                    accent: Theme.cyan
                )
                KPITile(label: "Touches", value: "\(viewModel.totalTouches)", accent: Theme.textPrimary)
                KPITile(label: "Total", value: "\(viewModel.sequences.count)", accent: Theme.textMuted)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(.thinMaterial)
    }

    private var statusBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                SelectablePill(label: "All", isSelected: viewModel.statusFilter == nil) {
                    viewModel.statusFilter = nil
                }
                ForEach(SequenceStatus.allCases, id: \.self) { status in
                    SelectablePill(
                        label: status.label,
                        isSelected: viewModel.statusFilter == status,
                        tint: SequencesView.tint(for: status)
                    ) {
                        viewModel.statusFilter = (viewModel.statusFilter == status) ? nil : status
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    private var list: some View {
        List {
            ForEach(viewModel.visibleSequences) { seq in
                NavigationLink(value: seq.id) {
                    SequenceRow(sequence: seq)
                }
                .listRowBackground(Theme.surface1)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    if seq.status == .active {
                        Button {
                            Task { await viewModel.setStatus(seq.id, to: .paused) }
                        } label: { Label("Pause", systemImage: "pause.circle") }
                        .tint(Theme.warning)
                    } else if seq.status == .paused {
                        Button {
                            Task { await viewModel.setStatus(seq.id, to: .active) }
                        } label: { Label("Resume", systemImage: "play.circle") }
                        .tint(Theme.accent)
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationDestination(for: EmailSequence.ID.self) { id in
            if let seq = viewModel.sequences.first(where: { $0.id == id }) {
                SequenceDetailView(sequence: seq)
            }
        }
    }

    static func tint(for status: SequenceStatus) -> Color {
        switch status {
        case .draft:     return Theme.textMuted
        case .active:    return Theme.accent
        case .paused:    return Theme.warning
        case .replied:   return Theme.cyan
        case .completed: return Theme.signalGlow
        case .bounced:   return Theme.danger
        }
    }
}

struct SequenceRow: View {
    let sequence: EmailSequence

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(sequence.recipientName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    StatusPill(label: sequence.status.label, tint: SequencesView.tint(for: sequence.status))
                }
                Text(sequence.subject)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textMuted)
                    .lineLimit(1)
                HStack(spacing: 10) {
                    Label("\(sequence.touchCount)", systemImage: "envelope")
                        .font(.workMono(10))
                        .foregroundStyle(Theme.textFaint)
                        .contentTransition(.numericText())
                    if let next = sequence.nextStepAt, sequence.status == .active {
                        Label(next.formatted(.relative(presentation: .named)),
                              systemImage: "clock.arrow.circlepath")
                            .font(.workMono(10))
                            .foregroundStyle(Theme.accent)
                    } else {
                        Text("last \(sequence.lastTouchedAt.formatted(.relative(presentation: .named)))")
                            .font(.workMono(10))
                            .foregroundStyle(Theme.textFaint)
                    }
                }
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct SequenceDetailView: View {
    let sequence: EmailSequence

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                StatusPill(label: sequence.status.label, tint: SequencesView.tint(for: sequence.status), size: 10)
                                Spacer()
                                Label("\(sequence.touchCount) touches", systemImage: "envelope")
                                    .font(.workMono(11))
                                    .foregroundStyle(Theme.textMuted)
                            }
                            Text(sequence.subject)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(Theme.textPrimary)
                            HStack(spacing: 10) {
                                meta(label: "To", value: sequence.recipientName)
                                meta(label: "Email", value: sequence.recipientEmail)
                            }
                            HStack(spacing: 10) {
                                meta(label: "Started", value: sequence.createdAt.formatted(date: .abbreviated, time: .omitted))
                                meta(label: "Last touch", value: sequence.lastTouchedAt.formatted(date: .abbreviated, time: .omitted))
                            }
                            if let next = sequence.nextStepAt {
                                meta(label: "Next step", value: next.formatted(date: .abbreviated, time: .shortened))
                            }
                        }
                    }
                    Text("Cadence editor lands in M3.")
                        .font(.workMono(10))
                        .foregroundStyle(Theme.textFaint)
                }
                .padding(16)
            }
        }
        .navigationTitle(sequence.recipientName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func meta(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).workUppercaseLabel(9, color: Theme.textFaint)
            Text(value).font(.workMono(11)).foregroundStyle(Theme.textPrimary)
        }
    }
}

#Preview {
    NavigationStack {
        SequencesView(viewModel: SequencesViewModel(repository: PreviewSequencesRepository()))
    }
}
