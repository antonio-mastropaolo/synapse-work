import SwiftUI
import WorkCore
import WorkUI

public struct ApprovalsView: View {
    @State private var viewModel: ApprovalsViewModel
    @State private var selection: Approval.ID?

    public init(viewModel: ApprovalsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                kpiStrip
                statusFilterBar
                Divider().background(Theme.border)
                approvalsList
            }
        }
        .preferredColorScheme(.dark)
        .navigationTitle("Approvals")
        .navigationBarTitleDisplayMode(.inline)
        .task { viewModel.start() }
        .refreshable { await viewModel.refresh() }
    }

    private var kpiStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                KPITile(
                    label: "Pending",
                    value: dollarString(viewModel.pendingCents),
                    trend: .flat("\(viewModel.totalsByStatus[.submitted]?.count ?? 0) submitted"),
                    accent: Theme.warning
                )
                KPITile(
                    label: "Paid YTD",
                    value: dollarString(viewModel.paidCents),
                    trend: .up("\(viewModel.totalsByStatus[.paid]?.count ?? 0) cleared"),
                    accent: Theme.accent
                )
                KPITile(
                    label: "Approved",
                    value: "\(viewModel.totalsByStatus[.approved]?.count ?? 0)",
                    accent: Theme.cyan
                )
                KPITile(
                    label: "Rejected",
                    value: "\(viewModel.totalsByStatus[.rejected]?.count ?? 0)",
                    accent: Theme.danger
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(.thinMaterial)
    }

    private var statusFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                SelectablePill(label: "All", isSelected: viewModel.statusFilter == nil) {
                    viewModel.statusFilter = nil
                }
                ForEach(Approval.Status.allCases, id: \.self) { status in
                    SelectablePill(
                        label: status.rawValue,
                        isSelected: viewModel.statusFilter == status,
                        tint: ApprovalsView.tint(for: status)
                    ) {
                        viewModel.statusFilter = (viewModel.statusFilter == status) ? nil : status
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    private var approvalsList: some View {
        List(selection: $selection) {
            ForEach(viewModel.visibleApprovals) { approval in
                NavigationLink(value: approval.id) {
                    ApprovalRow(approval: approval, receipts: viewModel.receipts)
                }
                .listRowBackground(Theme.surface1)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    if approval.status == .draft {
                        Button {
                            Task { await viewModel.setStatus(approval.id, to: .submitted) }
                        } label: { Label("Submit", systemImage: "paperplane") }
                        .tint(Theme.accent)
                    }
                    if approval.status == .submitted {
                        Button {
                            Task { await viewModel.setStatus(approval.id, to: .approved) }
                        } label: { Label("Approve", systemImage: "checkmark.seal") }
                        .tint(Theme.cyan)
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationDestination(for: Approval.ID.self) { id in
            if let approval = viewModel.approvals.first(where: { $0.id == id }) {
                ApprovalDetailView(approval: approval, receipts: viewModel.receipts)
            }
        }
    }

    private func dollarString(_ cents: Int) -> String {
        (Double(cents) / 100.0).formatted(.currency(code: "USD"))
    }

    static func tint(for status: Approval.Status) -> Color {
        switch status {
        case .draft:     return Theme.textMuted
        case .submitted: return Theme.warning
        case .approved:  return Theme.cyan
        case .paid:      return Theme.accent
        case .rejected:  return Theme.danger
        }
    }
}

struct ApprovalRow: View {
    let approval: Approval
    let receipts: [String: Receipt]

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(approval.vendor)
                        .workUppercaseLabel(9, color: Theme.textMuted)
                    StatusPill(label: approval.status.rawValue, tint: ApprovalsView.tint(for: approval.status))
                }
                Text(approval.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(2)
                HStack(spacing: 10) {
                    Label("\(approval.receiptIDs.count)", systemImage: "doc.text")
                        .font(.workMono(10))
                        .foregroundStyle(Theme.textFaint)
                    if let worktag = approval.worktag {
                        Text(worktag)
                            .font(.workMono(10))
                            .foregroundStyle(Theme.textFaint)
                    }
                    Spacer()
                    Text(approval.createdAt.formatted(.relative(presentation: .named)))
                        .font(.workMono(10))
                        .foregroundStyle(Theme.textFaint)
                }
            }
            Spacer(minLength: 6)
            Text(approval.amountFormatted)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Theme.textPrimary)
        }
        .padding(.vertical, 6)
    }
}

struct ApprovalDetailView: View {
    let approval: Approval
    let receipts: [String: Receipt]

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                StatusPill(label: approval.status.rawValue, tint: ApprovalsView.tint(for: approval.status), size: 10)
                                Spacer()
                                Text(approval.amountFormatted)
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .monospacedDigit()
                                    .foregroundStyle(Theme.textPrimary)
                            }
                            Text(approval.title)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(Theme.textPrimary)
                            HStack(spacing: 14) {
                                metaCell(label: "Vendor", value: approval.vendor)
                                metaCell(label: "Bucket", value: approval.bucket.rawValue.capitalized)
                                if let worktag = approval.worktag {
                                    metaCell(label: "Worktag", value: worktag)
                                }
                            }
                            HStack(spacing: 14) {
                                metaCell(label: "Created", value: approval.createdAt.formatted(date: .abbreviated, time: .omitted))
                                if let submittedAt = approval.submittedAt {
                                    metaCell(label: "Submitted", value: submittedAt.formatted(date: .abbreviated, time: .omitted))
                                }
                            }
                        }
                    }

                    Text("Linked receipts")
                        .workUppercaseLabel(10, color: Theme.textMuted)
                        .padding(.leading, 4)

                    ForEach(approval.receiptIDs, id: \.self) { rid in
                        if let receipt = receipts[rid] {
                            ReceiptCard(receipt: receipt)
                        }
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle(approval.vendor)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func metaCell(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).workUppercaseLabel(9, color: Theme.textFaint)
            Text(value).font(.workMono(11)).foregroundStyle(Theme.textPrimary)
        }
    }
}

struct ReceiptCard: View {
    let receipt: Receipt

    var body: some View {
        GlassCard {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 4) {
                    Text(receipt.subject)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(2)
                    HStack(spacing: 6) {
                        Text(receipt.documentKind.rawValue.uppercased())
                            .workUppercaseLabel(9, color: Theme.textFaint)
                        Text("·").foregroundStyle(Theme.textFaint)
                        Text(receipt.receivedAt.formatted(.relative(presentation: .named)))
                            .font(.workMono(10))
                            .foregroundStyle(Theme.textFaint)
                    }
                }
                Spacer()
                Text(receipt.amountFormatted)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Theme.textPrimary)
            }
        }
    }

    private var icon: String {
        switch receipt.documentKind {
        case .receipt: return "doc.text"
        case .invoice: return "doc.richtext"
        case .refund:  return "arrow.uturn.left.circle"
        case .unknown: return "questionmark.circle"
        }
    }
}

#Preview {
    NavigationStack {
        ApprovalsView(viewModel: ApprovalsViewModel(repository: PreviewApprovalsRepository()))
    }
}
