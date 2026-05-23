import Foundation
import WorkCore

public protocol ApprovalsRepositoryProtocol: Sendable {
    func stream() -> AsyncStream<ApprovalsSnapshot>
    func refresh() async throws
    func setStatus(id: Approval.ID, to status: Approval.Status) async throws
}

public struct ApprovalsSnapshot: Sendable, Equatable {
    public let approvals: [Approval]
    public let receipts: [String: Receipt]
    public let heartbeat: DaemonHeartbeat?

    public init(
        approvals: [Approval],
        receipts: [String: Receipt],
        heartbeat: DaemonHeartbeat?
    ) {
        self.approvals = approvals
        self.receipts = receipts
        self.heartbeat = heartbeat
    }
}

public actor PreviewApprovalsRepository: ApprovalsRepositoryProtocol {
    private var approvals: [Approval]
    private var receipts: [String: Receipt]
    private var continuations: [UUID: AsyncStream<ApprovalsSnapshot>.Continuation] = [:]

    public init(
        approvals: [Approval] = PreviewApprovalsRepository.approvalFixtures(),
        receipts: [Receipt] = PreviewApprovalsRepository.receiptFixtures()
    ) {
        self.approvals = approvals
        self.receipts = Dictionary(uniqueKeysWithValues: receipts.map { ($0.id, $0) })
    }

    public nonisolated func stream() -> AsyncStream<ApprovalsSnapshot> {
        AsyncStream { continuation in
            let token = UUID()
            Task { await self.register(token: token, continuation: continuation) }
            continuation.onTermination = { _ in
                Task { await self.unregister(token: token) }
            }
        }
    }

    private func register(token: UUID, continuation: AsyncStream<ApprovalsSnapshot>.Continuation) {
        continuations[token] = continuation
        continuation.yield(currentSnapshot())
    }

    private func unregister(token: UUID) { continuations[token] = nil }

    public func refresh() async throws { emit() }

    public func setStatus(id: Approval.ID, to status: Approval.Status) async throws {
        guard let idx = approvals.firstIndex(where: { $0.id == id }) else { return }
        approvals[idx].status = status
        emit()
    }

    private func emit() {
        let snapshot = currentSnapshot()
        for (_, continuation) in continuations { continuation.yield(snapshot) }
    }

    private func currentSnapshot() -> ApprovalsSnapshot {
        ApprovalsSnapshot(
            approvals: approvals,
            receipts: receipts,
            heartbeat: DaemonHeartbeat(lastTick: Date().addingTimeInterval(-180))
        )
    }

    public static func approvalFixtures() -> [Approval] {
        let now = Date()
        return [
            .init(
                id: "appr-001",
                title: "Claude API — April usage",
                vendor: "Anthropic",
                amountCents: 12_840,
                createdAt: now.addingTimeInterval(-86_400 * 3),
                submittedAt: now.addingTimeInterval(-86_400 * 2),
                bucket: .startup,
                status: .submitted,
                receiptIDs: ["rcpt-001", "rcpt-002"],
                worktag: "DS001368"
            ),
            .init(
                id: "appr-002",
                title: "ICSE 2026 registration",
                vendor: "ACM",
                amountCents: 89_500,
                createdAt: now.addingTimeInterval(-86_400 * 12),
                submittedAt: now.addingTimeInterval(-86_400 * 10),
                bucket: .conference,
                status: .approved,
                receiptIDs: ["rcpt-003"],
                worktag: "GR005334"
            ),
            .init(
                id: "appr-003",
                title: "Books — Designing Data-Intensive Applications + 2 more",
                vendor: "Amazon",
                amountCents: 14_270,
                createdAt: now.addingTimeInterval(-86_400 * 1),
                submittedAt: nil,
                bucket: .startup,
                status: .draft,
                receiptIDs: ["rcpt-004", "rcpt-005", "rcpt-006"],
                worktag: "DS001368"
            ),
            .init(
                id: "appr-004",
                title: "Flight LAX → BOS (FSE travel)",
                vendor: "Delta Air Lines",
                amountCents: 42_100,
                createdAt: now.addingTimeInterval(-86_400 * 30),
                submittedAt: now.addingTimeInterval(-86_400 * 25),
                bucket: .travel,
                status: .paid,
                receiptIDs: ["rcpt-007"],
                worktag: "GR005334"
            ),
            .init(
                id: "appr-005",
                title: "OpenAI API — March overage",
                vendor: "OpenAI",
                amountCents: 6_220,
                createdAt: now.addingTimeInterval(-86_400 * 40),
                submittedAt: now.addingTimeInterval(-86_400 * 38),
                bucket: .startup,
                status: .rejected,
                receiptIDs: ["rcpt-008"],
                worktag: "DS001368"
            ),
            .init(
                id: "appr-006",
                title: "Notion Team — Q2",
                vendor: "Notion Labs",
                amountCents: 4_800,
                createdAt: now.addingTimeInterval(-86_400 * 6),
                submittedAt: now.addingTimeInterval(-86_400 * 5),
                bucket: .startup,
                status: .submitted,
                receiptIDs: ["rcpt-009"],
                worktag: "DS001368"
            )
        ]
    }

    public static func receiptFixtures() -> [Receipt] {
        let now = Date()
        return [
            .init(id: "rcpt-001", vendor: "Anthropic", amountCents: 8_400, receivedAt: now.addingTimeInterval(-86_400 * 4), documentKind: .invoice, subject: "Anthropic — Invoice #INV-2026-04-08400"),
            .init(id: "rcpt-002", vendor: "Anthropic", amountCents: 4_440, receivedAt: now.addingTimeInterval(-86_400 * 4), documentKind: .receipt, subject: "Anthropic — Payment receipt April"),
            .init(id: "rcpt-003", vendor: "ACM", amountCents: 89_500, receivedAt: now.addingTimeInterval(-86_400 * 13), documentKind: .receipt, subject: "ICSE 2026 — registration confirmation"),
            .init(id: "rcpt-004", vendor: "Amazon", amountCents: 5_490, receivedAt: now.addingTimeInterval(-86_400 * 1), documentKind: .receipt, subject: "Order #112-DDIA"),
            .init(id: "rcpt-005", vendor: "Amazon", amountCents: 4_990, receivedAt: now.addingTimeInterval(-86_400 * 1), documentKind: .receipt, subject: "Order #112-SCS"),
            .init(id: "rcpt-006", vendor: "Amazon", amountCents: 3_790, receivedAt: now.addingTimeInterval(-86_400 * 1), documentKind: .receipt, subject: "Order #112-DSAA"),
            .init(id: "rcpt-007", vendor: "Delta Air Lines", amountCents: 42_100, receivedAt: now.addingTimeInterval(-86_400 * 31), documentKind: .receipt, subject: "Delta — eTicket confirmation"),
            .init(id: "rcpt-008", vendor: "OpenAI", amountCents: 6_220, receivedAt: now.addingTimeInterval(-86_400 * 41), documentKind: .invoice, subject: "OpenAI — Invoice #2026-03"),
            .init(id: "rcpt-009", vendor: "Notion Labs", amountCents: 4_800, receivedAt: now.addingTimeInterval(-86_400 * 6), documentKind: .receipt, subject: "Notion — quarterly receipt")
        ]
    }
}
