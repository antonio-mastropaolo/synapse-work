import Foundation
import WorkCore

public protocol ReviewsRepositoryProtocol: Sendable {
    func stream() -> AsyncStream<ReviewsSnapshot>
    func refresh() async throws
    func acceptInvitation(_ id: ReviewInvitation.ID) async throws
    func declineInvitation(_ id: ReviewInvitation.ID) async throws
    func updateVerdict(_ id: Review.ID, verdict: ReviewVerdict) async throws
    func updateBody(_ id: Review.ID, body: String) async throws
}

public struct ReviewsSnapshot: Sendable, Equatable {
    public let invitations: [ReviewInvitation]
    public let active: [Review]
    public let archived: [Review]

    public init(invitations: [ReviewInvitation], active: [Review], archived: [Review]) {
        self.invitations = invitations
        self.active = active
        self.archived = archived
    }
}

public actor PreviewReviewsRepository: ReviewsRepositoryProtocol {
    private var invitations: [ReviewInvitation]
    private var active: [Review]
    private var archived: [Review]
    private var continuations: [UUID: AsyncStream<ReviewsSnapshot>.Continuation] = [:]

    public init() {
        self.invitations = PreviewReviewsRepository.invitationFixtures()
        self.active = PreviewReviewsRepository.activeFixtures()
        self.archived = PreviewReviewsRepository.archivedFixtures()
    }

    public nonisolated func stream() -> AsyncStream<ReviewsSnapshot> {
        AsyncStream { continuation in
            let token = UUID()
            Task { await self.register(token: token, continuation: continuation) }
            continuation.onTermination = { _ in Task { await self.unregister(token: token) } }
        }
    }

    private func register(token: UUID, continuation: AsyncStream<ReviewsSnapshot>.Continuation) {
        continuations[token] = continuation
        continuation.yield(snapshot)
    }

    private func unregister(token: UUID) { continuations[token] = nil }
    private var snapshot: ReviewsSnapshot { ReviewsSnapshot(invitations: invitations, active: active, archived: archived) }
    private func emit() { for (_, c) in continuations { c.yield(snapshot) } }

    public func refresh() async throws { emit() }

    public func acceptInvitation(_ id: ReviewInvitation.ID) async throws {
        guard let idx = invitations.firstIndex(where: { $0.id == id }) else { return }
        let inv = invitations.remove(at: idx)
        active.append(.init(
            id: "rev-\(inv.id)", venue: inv.venue, manuscriptId: inv.manuscriptId, manuscriptTitle: inv.manuscriptTitle,
            authors: ["TBD"], deadline: inv.deadline, kind: inv.kind,
            verdict: .undecided, stage: .fetched, bodyMarkdown: "", pageCount: 0
        ))
        emit()
    }

    public func declineInvitation(_ id: ReviewInvitation.ID) async throws {
        invitations.removeAll { $0.id == id }
        emit()
    }

    public func updateVerdict(_ id: Review.ID, verdict: ReviewVerdict) async throws {
        if let idx = active.firstIndex(where: { $0.id == id }) {
            active[idx].verdict = verdict
            emit()
        }
    }

    public func updateBody(_ id: Review.ID, body: String) async throws {
        if let idx = active.firstIndex(where: { $0.id == id }) {
            active[idx].bodyMarkdown = body
            emit()
        }
    }

    static func invitationFixtures() -> [ReviewInvitation] {
        let now = Date()
        return [
            .init(id: "inv-001", venue: "ASE 2026",       manuscriptId: "ASE-2026-RT-088", manuscriptTitle: "Retrieval-Augmented Repair Beyond Single-Snippet Patches", invitedAt: now.addingTimeInterval(-86_400 * 2), deadline: now.addingTimeInterval(86_400 * 14), kind: .conference, editor: "Lin Tan"),
            .init(id: "inv-002", venue: "TSE",            manuscriptId: "TSE-2026-04-1421", manuscriptTitle: "On the Stability of LLM-Driven Refactoring Suggestions Across Compilers", invitedAt: now.addingTimeInterval(-86_400 * 5), deadline: now.addingTimeInterval(86_400 * 21), kind: .journal, editor: "Tim Menzies"),
            .init(id: "inv-003", venue: "FSE 2026",       manuscriptId: "FSE-2026-S-204", manuscriptTitle: "Counterfactual Fault Localization with Code LLMs", invitedAt: now.addingTimeInterval(-86_400 * 1), deadline: now.addingTimeInterval(86_400 * 10), kind: .conference, editor: "Reid Holmes"),
        ]
    }

    static func activeFixtures() -> [Review] {
        let now = Date()
        return [
            .init(id: "rev-101", venue: "TOSEM",   manuscriptId: "TOSEM-2025-1266", manuscriptTitle: "A Causal Lens on Code-LLM Reasoning", authors: ["J. Park", "S. Liu", "H. Suresh"], deadline: now.addingTimeInterval(86_400 * 5),  kind: .journal,    verdict: .minorRevision, stage: .drafted,   bodyMarkdown: "## Summary\nThe paper presents a causal analysis...\n\n## Strengths\n- Novel evaluation protocol\n- Strong empirical results on three benchmarks\n\n## Weaknesses\n- Limited statistical analysis on RQ2\n- Section 4.3 conflates correlation with causation in one diagram\n\n## Detailed comments\n...", pageCount: 28),
            .init(id: "rev-102", venue: "ICSE 2026", manuscriptId: "ICSE-2026-RT-411", manuscriptTitle: "Multi-Agent Debate Improves Test Generation: A Reproducibility Study", authors: ["M. Rodriguez", "K. Tanaka"], deadline: now.addingTimeInterval(86_400 * 9),  kind: .conference, verdict: .undecided,     stage: .summarized, bodyMarkdown: "## Initial impressions\nReproducibility claim is well-motivated. Need to check artifact appendix before drafting.\n", pageCount: 18),
        ]
    }

    static func archivedFixtures() -> [Review] {
        let now = Date()
        return [
            .init(id: "rev-099", venue: "EMSE",      manuscriptId: "EMSE-D-26-00412", manuscriptTitle: "Empirical Study of LLM-Driven Refactoring",         authors: ["A. Chen"],                    deadline: now.addingTimeInterval(-86_400 * 14), kind: .journal,    verdict: .accept,         stage: .submitted, bodyMarkdown: "Accept after minor copy-edits.", pageCount: 22),
            .init(id: "rev-098", venue: "ASE 2025", manuscriptId: "ASE-2025-RT-052", manuscriptTitle: "Property-Based Test Generation in the LLM Era",     authors: ["R. Brooks", "T. Halim"],     deadline: now.addingTimeInterval(-86_400 * 90), kind: .conference, verdict: .majorRevision,  stage: .submitted, bodyMarkdown: "Major revision — methodology section needs restructuring.", pageCount: 16),
        ]
    }
}
