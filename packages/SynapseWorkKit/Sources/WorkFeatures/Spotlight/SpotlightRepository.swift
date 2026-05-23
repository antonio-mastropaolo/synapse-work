import Foundation
import WorkCore

public protocol SpotlightRepositoryProtocol: Sendable {
    func stream() -> AsyncStream<[SpotlightEvent]>
    func refresh() async throws
    func setStatus(id: SpotlightEvent.ID, to status: SpotlightEvent.Status) async throws
}

public actor PreviewSpotlightRepository: SpotlightRepositoryProtocol {
    private var events: [SpotlightEvent]
    private var continuations: [UUID: AsyncStream<[SpotlightEvent]>.Continuation] = [:]

    public init(events: [SpotlightEvent] = PreviewSpotlightRepository.fixtures()) {
        self.events = events
    }

    public nonisolated func stream() -> AsyncStream<[SpotlightEvent]> {
        AsyncStream { continuation in
            let token = UUID()
            Task { await self.register(token: token, continuation: continuation) }
            continuation.onTermination = { _ in
                Task { await self.unregister(token: token) }
            }
        }
    }

    private func register(
        token: UUID,
        continuation: AsyncStream<[SpotlightEvent]>.Continuation
    ) {
        continuations[token] = continuation
        continuation.yield(events)
    }

    private func unregister(token: UUID) {
        continuations[token] = nil
    }

    public func refresh() async throws {
        // Preview repo is in-memory; refresh is a no-op aside from re-emitting.
        emit()
    }

    public func setStatus(id: SpotlightEvent.ID, to status: SpotlightEvent.Status) async throws {
        guard let idx = events.firstIndex(where: { $0.id == id }) else { return }
        events[idx].status = status
        emit()
    }

    private func emit() {
        for (_, continuation) in continuations { continuation.yield(events) }
    }

    public static func fixtures() -> [SpotlightEvent] {
        let now = Date()
        return [
            .init(
                id: "spot-1",
                title: "Towards Causal Reasoning in Code LLMs",
                abstract: "A new benchmark for evaluating causal vs. correlational reasoning in 7B code models, with surprising findings on chain-of-thought collapse under counterfactual prompts.",
                venue: "ICSE 2026",
                detectedAt: now.addingTimeInterval(-3_600),
                kind: .pick,
                status: .pending
            ),
            .init(
                id: "spot-2",
                title: "On the Stability of Retrieval-Augmented Code Repair",
                abstract: "Authors show that retrieval rerankers introduce non-determinism in repair outcomes — a single different doc in context flips 12% of fixes. Includes a deterministic-rerank patch.",
                venue: "FSE 2026",
                detectedAt: now.addingTimeInterval(-7_200),
                kind: .draftReady,
                status: .pending
            ),
            .init(
                id: "spot-3",
                title: "Multi-Agent Debate Improves Test Generation",
                abstract: "Three-agent debate (proposer/critic/synthesizer) produces 23% higher mutation-kill rates than single-agent generation on Defects4J. Cost overhead 2.4x — discussed.",
                venue: "ASE 2026",
                detectedAt: now.addingTimeInterval(-10_800),
                kind: .network,
                status: .acknowledged
            )
        ]
    }
}
