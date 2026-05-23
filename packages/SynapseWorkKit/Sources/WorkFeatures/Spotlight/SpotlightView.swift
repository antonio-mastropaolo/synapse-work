import SwiftUI
import WorkCore
import WorkUI

public struct SpotlightView: View {
    @State private var viewModel: SpotlightViewModel
    @State private var selection: SpotlightEvent.ID?

    public init(viewModel: SpotlightViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            content
        }
        .preferredColorScheme(.dark)
        .navigationTitle("Spotlight")
        .navigationBarTitleDisplayMode(.inline)
        .task { viewModel.start() }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.events.isEmpty {
            ContentUnavailableView(
                "No spotlight events",
                systemImage: "sparkles",
                description: Text("New papers will land here as the daemon detects them.")
            )
        } else {
            TabView(selection: $selection) {
                ForEach(viewModel.events) { event in
                    SpotlightCardView(event: event) { newStatus in
                        Task { await viewModel.setStatus(event.id, to: newStatus) }
                    }
                    .padding(20)
                    .tag(Optional(event.id))
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .onAppear { selection = viewModel.events.first?.id }
        }
    }
}

struct SpotlightCardView: View {
    let event: SpotlightEvent
    let onStatusChange: (SpotlightEvent.Status) -> Void

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    kindBadge
                    Spacer()
                    statusPill
                }

                Text(event.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                if let venue = event.venue {
                    Text(venue)
                        .workUppercaseLabel(10, color: Theme.textMuted)
                }

                Text(event.abstract)
                    .font(.workBody(13))
                    .foregroundStyle(Theme.textMuted)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                HStack(spacing: 10) {
                    actionButton("Acknowledge", systemImage: "checkmark", tint: Theme.accent) {
                        onStatusChange(.acknowledged)
                    }
                    actionButton("Dismiss", systemImage: "xmark", tint: Theme.danger) {
                        onStatusChange(.dismissed)
                    }
                }

                Text(event.detectedAt.formatted(.relative(presentation: .named)))
                    .font(.workMono(10))
                    .foregroundStyle(Theme.textFaint)
            }
        }
    }

    private var kindBadge: some View {
        Text(badgeLabel)
            .workUppercaseLabel(9, color: Theme.accent)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Theme.accent.opacity(0.12), in: Capsule())
            .overlay(Capsule().stroke(Theme.accent.opacity(0.4), lineWidth: 0.5))
    }

    private var badgeLabel: String {
        switch event.kind {
        case .pick:       return "PICK"
        case .draftReady: return "DRAFT READY"
        case .network:    return "NETWORK"
        }
    }

    private var statusPill: some View {
        Text(event.status.rawValue)
            .workUppercaseLabel(9, color: statusColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.10), in: Capsule())
    }

    private var statusColor: Color {
        switch event.status {
        case .pending:      return Theme.warning
        case .acknowledged: return Theme.cyan
        case .actioned:     return Theme.accent
        case .dismissed:    return Theme.textFaint
        }
    }

    private func actionButton(
        _ label: String,
        systemImage: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(label, systemImage: systemImage)
                .font(.workMono(11))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
        }
        .buttonStyle(.borderedProminent)
        .tint(tint.opacity(0.18))
        .foregroundStyle(tint)
    }
}

#Preview {
    NavigationStack {
        SpotlightView(viewModel: SpotlightViewModel(repository: PreviewSpotlightRepository()))
    }
}
