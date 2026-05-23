import SwiftUI
import WorkCore
import WorkUI

public struct InboxView: View {
    @State private var viewModel: InboxViewModel
    @State private var selection: InboxMessage.ID?

    public init(viewModel: InboxViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            list
        }
        .preferredColorScheme(.dark)
        .navigationTitle("Inbox")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always))
        .searchScopes($viewModel.scope) {
            Text("All").tag(InboxViewModel.InboxScope.all)
            ForEach(InboxTag.allCases, id: \.self) { tag in
                Text(tag.label).tag(InboxViewModel.InboxScope.tag(tag))
            }
        }
        .task { viewModel.start() }
        .refreshable { await viewModel.refresh() }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if viewModel.unreadCount > 0 {
                    StatusPill(label: "\(viewModel.unreadCount) NEW", tint: Theme.accent)
                }
            }
        }
    }

    private var list: some View {
        List(selection: $selection) {
            ForEach(viewModel.groupedByBand(), id: \.band) { group in
                Section {
                    ForEach(group.items) { msg in
                        NavigationLink(value: msg.id) {
                            InboxRow(message: msg)
                        }
                        .listRowBackground(Theme.surface1)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                Task { await viewModel.archive(msg.id) }
                            } label: { Label("Archive", systemImage: "archivebox") }
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button {
                                Task { await viewModel.markRead(msg.id, isRead: !msg.isRead) }
                            } label: {
                                Label(msg.isRead ? "Unread" : "Read",
                                      systemImage: msg.isRead ? "envelope.badge" : "envelope.open")
                            }
                            .tint(Theme.cyan)
                        }
                    }
                } header: {
                    WorkSectionHeader(group.band.uppercased(), count: group.items.count)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationDestination(for: InboxMessage.ID.self) { id in
            if let msg = viewModel.messages.first(where: { $0.id == id }) {
                InboxDetailView(message: msg)
            }
        }
    }
}

struct InboxRow: View {
    let message: InboxMessage

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Rectangle()
                .fill(sourceColor)
                .frame(width: 2)
                .padding(.vertical, 2)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(message.sender)
                        .font(.system(size: 13, weight: message.isRead ? .regular : .bold))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)
                    Spacer()
                    Text(message.receivedAt.formatted(.relative(presentation: .named)))
                        .font(.workMono(10))
                        .foregroundStyle(Theme.textFaint)
                }
                Text(message.subject)
                    .font(.system(size: 13, weight: message.isRead ? .regular : .semibold))
                    .foregroundStyle(message.isRead ? Theme.textMuted : Theme.textPrimary)
                    .lineLimit(2)
                Text(message.preview)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textFaint)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    StatusPill(label: message.tag.label, tint: tagTint)
                    Text(message.source.label)
                        .workUppercaseLabel(9, color: Theme.textFaint)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var sourceColor: Color {
        switch message.source {
        case .gmail:    return SourceColor.gmail.swiftUIColor
        case .outlook:  return SourceColor.outlook.swiftUIColor
        case .calendar: return SourceColor.calendar.swiftUIColor
        case .slack:    return SourceColor.slack.swiftUIColor
        case .discord:  return SourceColor.discord.swiftUIColor
        case .unknown:  return SourceColor.unknown.swiftUIColor
        }
    }

    private var tagTint: Color {
        switch message.tag {
        case .review:    return Theme.violet
        case .approval:  return Theme.accent
        case .spotlight: return Theme.cyan
        case .meeting:   return Theme.warning
        case .student:   return Theme.cyan
        case .admin:     return Theme.textMuted
        case .grant:     return Theme.signalGlow
        case .travel:    return Theme.warning
        case .other:     return Theme.textMuted
        }
    }
}

struct InboxDetailView: View {
    let message: InboxMessage

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 10) {
                        StatusPill(label: message.tag.label, tint: Theme.cyan)
                        StatusPill(label: message.source.label, tint: Theme.textMuted)
                        Spacer()
                        Text(message.receivedAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.workMono(11))
                            .foregroundStyle(Theme.textFaint)
                    }
                    Text(message.subject)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    HStack(spacing: 8) {
                        Text("From")
                            .workUppercaseLabel(9, color: Theme.textFaint)
                        Text(message.sender)
                            .font(.workMono(12))
                            .foregroundStyle(Theme.textPrimary)
                    }
                    Divider().background(Theme.border)
                    Text(message.preview)
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Full body sync ships in M3 — this is a preview repository.")
                        .font(.workMono(10))
                        .foregroundStyle(Theme.textFaint)
                        .padding(.top, 12)
                }
                .padding(20)
            }
        }
        .navigationTitle(message.sender)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        InboxView(viewModel: InboxViewModel(repository: PreviewInboxRepository()))
    }
}
