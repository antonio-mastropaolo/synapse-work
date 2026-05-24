import Foundation
import Models
public protocol SequencesRepositoryProtocol: Sendable {
    func stream() -> AsyncStream<[EmailSequence]>
    func refresh() async throws
    func setStatus(id: EmailSequence.ID, to status: SequenceStatus) async throws
}

public actor PreviewSequencesRepository: SequencesRepositoryProtocol {
    private var sequences: [EmailSequence]
    private var continuations: [UUID: AsyncStream<[EmailSequence]>.Continuation] = [:]

    public init(sequences: [EmailSequence] = PreviewSequencesRepository.fixtures()) {
        self.sequences = sequences
    }

    public nonisolated func stream() -> AsyncStream<[EmailSequence]> {
        AsyncStream { continuation in
            let token = UUID()
            Task { await self.register(token: token, continuation: continuation) }
            continuation.onTermination = { _ in
                Task { await self.unregister(token: token) }
            }
        }
    }

    private func register(token: UUID, continuation: AsyncStream<[EmailSequence]>.Continuation) {
        continuations[token] = continuation
        continuation.yield(sequences)
    }

    private func unregister(token: UUID) { continuations[token] = nil }

    public func refresh() async throws { emit() }

    public func setStatus(id: EmailSequence.ID, to status: SequenceStatus) async throws {
        guard let idx = sequences.firstIndex(where: { $0.id == id }) else { return }
        sequences[idx].status = status
        emit()
    }

    private func emit() {
        for (_, continuation) in continuations { continuation.yield(sequences) }
    }

    public static func fixtures() -> [EmailSequence] {
        let now = Date()
        return [
            .init(id: "seq-001", recipientName: "Mike Ernst", recipientEmail: "mernst@cs.washington.edu", subject: "ICSE 2026 PC member follow-up", createdAt: now.addingTimeInterval(-86_400 * 14), lastTouchedAt: now.addingTimeInterval(-86_400 * 2), status: .active, touchCount: 2, nextStepAt: now.addingTimeInterval(86_400 * 3)),
            .init(id: "seq-002", recipientName: "Lin Tan", recipientEmail: "lin@purdue.edu", subject: "ASE 2026 — joint workshop proposal", createdAt: now.addingTimeInterval(-86_400 * 7), lastTouchedAt: now.addingTimeInterval(-86_400 * 1), status: .replied, touchCount: 1, nextStepAt: nil),
            .init(id: "seq-003", recipientName: "Reid Holmes", recipientEmail: "rtholmes@cs.ubc.ca", subject: "Collaboration — code-LLM benchmarks", createdAt: now.addingTimeInterval(-86_400 * 21), lastTouchedAt: now.addingTimeInterval(-86_400 * 5), status: .active, touchCount: 3, nextStepAt: now.addingTimeInterval(86_400 * 2)),
            .init(id: "seq-004", recipientName: "Hannah Lin", recipientEmail: "hlin@google.com", subject: "Coffee at FSE? Boston Aug 15-18", createdAt: now.addingTimeInterval(-86_400 * 3), lastTouchedAt: now.addingTimeInterval(-86_400 * 3), status: .active, touchCount: 1, nextStepAt: now.addingTimeInterval(86_400 * 4)),
            .init(id: "seq-005", recipientName: "Tim Menzies", recipientEmail: "timm@ieee.org", subject: "TSE special issue — code-LLM eval", createdAt: now.addingTimeInterval(-86_400 * 30), lastTouchedAt: now.addingTimeInterval(-86_400 * 10), status: .paused, touchCount: 4, nextStepAt: nil),
            .init(id: "seq-006", recipientName: "Margaret Wang", recipientEmail: "mwang@anthropic.com", subject: "Anthropic Academic — pilot conversation", createdAt: now.addingTimeInterval(-86_400 * 18), lastTouchedAt: now.addingTimeInterval(-86_400 * 6), status: .completed, touchCount: 5, nextStepAt: nil),
            .init(id: "seq-007", recipientName: "Brad Myers", recipientEmail: "bam@cs.cmu.edu", subject: "PL/SE intersection — survey co-author", createdAt: now.addingTimeInterval(-86_400 * 45), lastTouchedAt: now.addingTimeInterval(-86_400 * 14), status: .bounced, touchCount: 2, nextStepAt: nil),
            .init(id: "seq-008", recipientName: "Alex Aiken", recipientEmail: "aiken@cs.stanford.edu", subject: "ML4Code workshop — keynote sounding", createdAt: now.addingTimeInterval(-86_400 * 8), lastTouchedAt: now.addingTimeInterval(-86_400 * 8), status: .draft, touchCount: 0, nextStepAt: nil),
        ]
    }
}
