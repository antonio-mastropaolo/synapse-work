import SwiftUI
import WorkCore
import WorkUI

public struct TimelineView: View {
    @State private var viewModel: TimelineViewModel

    public init(viewModel: TimelineViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    heroPanel
                    deadlinesSection
                    actionItemsSection
                    silentThreadsSection
                    Spacer(minLength: 24)
                }
                .padding(16)
            }
        }
        .preferredColorScheme(.dark)
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.inline)
        .task { viewModel.start() }
        .refreshable { await viewModel.refresh() }
    }

    private var heroPanel: some View {
        let stats = viewModel.snapshot.heroStats
        return VStack(alignment: .leading, spacing: 10) {
            Text("Today").workUppercaseLabel(10, color: Theme.textMuted)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                KPITile(label: "Inbox", value: "\(stats.unreadInbox)", trend: .flat("unread"), accent: Theme.cyan)
                KPITile(label: "Approvals", value: "\(stats.pendingApprovals)", trend: .flat("pending"), accent: Theme.warning)
                KPITile(label: "Reviews", value: "\(stats.activeReviews)", trend: .flat("active"), accent: Theme.violet)
                KPITile(label: "Sequences", value: "\(stats.activeSequences)", trend: .up("running"), accent: Theme.accent)
                KPITile(label: "Spotlight", value: "\(stats.spotlightToday)", trend: .flat("today"), accent: Theme.accent)
                KPITile(label: "Urgent", value: "\(stats.urgentDeadlines)", trend: .down("≤3d"), accent: Theme.danger)
            }
        }
    }

    private var deadlinesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Upcoming deadlines").workUppercaseLabel(10, color: Theme.textMuted)
                Spacer()
                Text("\(viewModel.snapshot.upcomingDeadlines.filter { !$0.dismissed }.count)")
                    .font(.workMono(10))
                    .foregroundStyle(Theme.textFaint)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(viewModel.snapshot.upcomingDeadlines.filter { !$0.dismissed }) { d in
                        DeadlineCard(deadline: d)
                            .frame(width: 240)
                    }
                }
            }
        }
    }

    private var actionItemsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Action items").workUppercaseLabel(10, color: Theme.textMuted)
            VStack(spacing: 6) {
                ForEach(viewModel.snapshot.actionItems) { item in
                    ActionItemRow(item: item)
                }
            }
        }
    }

    private var silentThreadsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Silent threads").workUppercaseLabel(10, color: Theme.textMuted)
            VStack(spacing: 6) {
                ForEach(viewModel.snapshot.silentThreads) { thread in
                    SilentThreadRow(thread: thread)
                }
            }
        }
    }
}

struct DeadlineCard: View {
    let deadline: ConferenceDeadline

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    StatusPill(label: deadline.kind.label, tint: kindTint)
                    Spacer()
                    Text("\(max(deadline.daysUntil, 0))d")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(deadline.daysUntil < 7 ? Theme.danger : Theme.textPrimary)
                }
                Text(deadline.conferenceCode)
                    .workUppercaseLabel(10, color: Theme.accent)
                Text(deadline.conferenceName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(2)
                if let loc = deadline.location {
                    Label(loc, systemImage: "mappin.and.ellipse")
                        .font(.workMono(10))
                        .foregroundStyle(Theme.textFaint)
                }
                Text(deadline.deadline.formatted(date: .abbreviated, time: .shortened))
                    .font(.workMono(10))
                    .foregroundStyle(Theme.textFaint)
            }
        }
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

struct ActionItemRow: View {
    let item: ActionItem

    var body: some View {
        HStack(spacing: 10) {
            Rectangle()
                .fill(priorityColor)
                .frame(width: 2)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    if let due = item.dueAt {
                        Text(due.formatted(.relative(presentation: .named)))
                            .font(.workMono(10))
                            .foregroundStyle(due.timeIntervalSinceNow < 3 * 86_400 ? Theme.danger : Theme.textFaint)
                    }
                }
                HStack(spacing: 6) {
                    Text(item.surface).workUppercaseLabel(9, color: Theme.textFaint)
                    Text("·").foregroundStyle(Theme.textFaint)
                    Text(item.context).font(.workMono(10)).foregroundStyle(Theme.textMuted)
                }
            }
            .padding(.vertical, 8)
            .padding(.trailing, 12)
        }
        .background(Theme.surface1, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Theme.border, lineWidth: 0.5)
        )
    }

    private var priorityColor: Color {
        switch item.priority {
        case .low:     return Theme.textMuted
        case .medium:  return Theme.cyan
        case .high:    return Theme.warning
        case .urgent:  return Theme.danger
        }
    }
}

struct SilentThreadRow: View {
    let thread: SilentThread

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "envelope.badge.shield.half.filled")
                .font(.system(size: 14))
                .foregroundStyle(Theme.textMuted)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(thread.counterpart)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Text("\(thread.daysSilent)d silent")
                        .font(.workMono(10))
                        .foregroundStyle(thread.daysSilent > 7 ? Theme.warning : Theme.textFaint)
                }
                Text(thread.subject)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textMuted)
                    .lineLimit(1)
            }
        }
        .padding(10)
        .background(Theme.surface1, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Theme.border, lineWidth: 0.5)
        )
    }
}

#Preview {
    NavigationStack {
        TimelineView(viewModel: TimelineViewModel(repository: PreviewTimelineRepository()))
    }
}
