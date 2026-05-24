import SwiftUI
import Models
import DesignSystem
public struct ReviewsView: View {
    @State private var viewModel: ReviewsViewModel

    public init(viewModel: ReviewsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                sectionPicker
                Divider().background(Theme.border)
                content
            }
        }
        .preferredColorScheme(.dark)
        .navigationTitle("Reviews")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task { viewModel.start() }
        .refreshable { await viewModel.refresh() }
    }

    private var sectionPicker: some View {
        HStack(spacing: 8) {
            ForEach(ReviewsViewModel.Section.allCases, id: \.self) { s in
                let count = countFor(s)
                SelectablePill(
                    label: "\(s.label) (\(count))",
                    isSelected: viewModel.section == s
                ) {
                    viewModel.section = s
                }
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func countFor(_ s: ReviewsViewModel.Section) -> Int {
        switch s {
        case .invitations: return viewModel.snapshot.invitations.count
        case .active:      return viewModel.snapshot.active.count
        case .archive:     return viewModel.snapshot.archived.count
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.section {
        case .invitations: invitationsList
        case .active:      activeList
        case .archive:     archiveList
        }
    }

    private var invitationsList: some View {
        List {
            ForEach(viewModel.snapshot.invitations) { inv in
                InvitationCard(invitation: inv) {
                    Task { await viewModel.accept(inv.id) }
                } onDecline: {
                    Task { await viewModel.decline(inv.id) }
                }
                .listRowBackground(Color.clear)
                .listRowInsets(.init(top: 6, leading: 16, bottom: 6, trailing: 16))
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Theme.background)
    }

    private var activeList: some View {
        List {
            ForEach(viewModel.snapshot.active) { review in
                NavigationLink(value: review.id) {
                    ReviewRow(review: review)
                }
                .listRowBackground(Theme.surface1)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationDestination(for: Review.ID.self) { id in
            if let review = viewModel.snapshot.active.first(where: { $0.id == id })
                ?? viewModel.snapshot.archived.first(where: { $0.id == id }) {
                ReviewDetailView(review: review) { v in
                    Task { await viewModel.setVerdict(review.id, v) }
                } onBodyChange: { body in
                    Task { await viewModel.updateBody(review.id, body) }
                }
            }
        }
    }

    private var archiveList: some View {
        List {
            ForEach(viewModel.snapshot.archived) { review in
                NavigationLink(value: review.id) {
                    ReviewRow(review: review)
                }
                .listRowBackground(Theme.surface1)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Theme.background)
    }
}

struct InvitationCard: View {
    let invitation: ReviewInvitation
    let onAccept: () -> Void
    let onDecline: () -> Void

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    StatusPill(label: invitation.venue, tint: Theme.violet)
                    StatusPill(label: invitation.kind.label, tint: Theme.textMuted)
                    Spacer()
                    Text(invitation.manuscriptId)
                        .font(.workMono(10))
                        .foregroundStyle(Theme.textFaint)
                }
                Text(invitation.manuscriptTitle)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(3)
                HStack(spacing: 14) {
                    if let ed = invitation.editor {
                        Label(ed, systemImage: "person.badge.shield.checkmark")
                            .font(.workMono(10))
                            .foregroundStyle(Theme.textMuted)
                    }
                    Spacer()
                    Label(invitation.deadline.formatted(.relative(presentation: .named)),
                          systemImage: "clock")
                        .font(.workMono(10))
                        .foregroundStyle(Theme.warning)
                }
                HStack(spacing: 8) {
                    Button(action: onAccept) {
                        Label("Accept", systemImage: "checkmark")
                            .font(.workMono(11))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.accent.opacity(0.18))
                    .foregroundStyle(Theme.accent)

                    Button(action: onDecline) {
                        Label("Decline", systemImage: "xmark")
                            .font(.workMono(11))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.danger.opacity(0.18))
                    .foregroundStyle(Theme.danger)
                }
            }
        }
    }
}

struct ReviewRow: View {
    let review: Review

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                StatusPill(label: review.venue, tint: Theme.violet)
                StatusPill(label: review.verdict.label, tint: verdictTint)
                Spacer()
                Text(review.manuscriptId)
                    .font(.workMono(10))
                    .foregroundStyle(Theme.textFaint)
            }
            Text(review.manuscriptTitle)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(2)
            HStack(spacing: 10) {
                Label("\(review.pageCount)p", systemImage: "doc")
                    .font(.workMono(10))
                    .foregroundStyle(Theme.textFaint)
                Label(review.stage.rawValue, systemImage: "circle.dashed.inset.filled")
                    .font(.workMono(10))
                    .foregroundStyle(Theme.cyan)
                Spacer()
                Text(review.deadline.formatted(.relative(presentation: .named)))
                    .font(.workMono(10))
                    .foregroundStyle(review.deadline.timeIntervalSinceNow < 7 * 86_400 ? Theme.warning : Theme.textFaint)
            }
        }
        .padding(.vertical, 4)
    }

    private var verdictTint: Color {
        switch review.verdict {
        case .accept:        return Theme.accent
        case .minorRevision: return Theme.cyan
        case .majorRevision: return Theme.warning
        case .reject:        return Theme.danger
        case .undecided:     return Theme.textMuted
        }
    }
}

struct ReviewDetailView: View {
    let review: Review
    let onVerdictChange: (ReviewVerdict) -> Void
    let onBodyChange: (String) -> Void

    @State private var bodyText: String = ""
    @State private var currentVerdict: ReviewVerdict = .undecided

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                StatusPill(label: review.venue, tint: Theme.violet)
                                StatusPill(label: review.kind.label, tint: Theme.textMuted)
                                Spacer()
                                Text(review.manuscriptId)
                                    .font(.workMono(10))
                                    .foregroundStyle(Theme.textFaint)
                            }
                            Text(review.manuscriptTitle)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(Theme.textPrimary)
                            Text(review.authors.joined(separator: " · "))
                                .font(.workMono(11))
                                .foregroundStyle(Theme.textMuted)
                            HStack(spacing: 10) {
                                meta("Pages", "\(review.pageCount)")
                                meta("Stage", review.stage.rawValue)
                                meta("Due", review.deadline.formatted(date: .abbreviated, time: .omitted))
                            }
                        }
                    }

                    pdfPanePlaceholder

                    verdictPicker

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Review (Markdown)").workUppercaseLabel(10, color: Theme.textMuted)
                        TextEditor(text: $bodyText)
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundStyle(Theme.textPrimary)
                            .scrollContentBackground(.hidden)
                            .background(Theme.surface1)
                            .frame(minHeight: 260)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(Theme.border, lineWidth: 0.5)
                            )
                            .onChange(of: bodyText) { _, new in onBodyChange(new) }
                    }
                }
                .padding(16)
            }
        }
        .onAppear {
            bodyText = review.bodyMarkdown
            currentVerdict = review.verdict
        }
        .navigationTitle(review.venue)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private var pdfPanePlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Theme.surface1)
            VStack(spacing: 8) {
                Image(systemName: "doc.richtext")
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(Theme.textMuted)
                Text("PDF viewer ships with PDFKit in M4")
                    .workUppercaseLabel(10, color: Theme.textMuted)
                Text("Manuscript would render here side-by-side with the editor on iPad/Mac")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textFaint)
            }
        }
        .frame(height: 200)
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Theme.border, lineWidth: 0.5)
        )
    }

    private var verdictPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Verdict").workUppercaseLabel(10, color: Theme.textMuted)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ReviewVerdict.allCases, id: \.self) { v in
                        SelectablePill(
                            label: v.label,
                            isSelected: currentVerdict == v,
                            tint: verdictTint(v)
                        ) {
                            currentVerdict = v
                            onVerdictChange(v)
                        }
                    }
                }
            }
        }
    }

    private func verdictTint(_ v: ReviewVerdict) -> Color {
        switch v {
        case .accept:        return Theme.accent
        case .minorRevision: return Theme.cyan
        case .majorRevision: return Theme.warning
        case .reject:        return Theme.danger
        case .undecided:     return Theme.textMuted
        }
    }

    private func meta(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label).workUppercaseLabel(9, color: Theme.textFaint)
            Text(value).font(.workMono(11)).foregroundStyle(Theme.textPrimary)
        }
    }
}

#Preview {
    NavigationStack {
        ReviewsView(viewModel: ReviewsViewModel(repository: PreviewReviewsRepository()))
    }
}
