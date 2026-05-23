import Foundation
import WorkCore

public protocol AskRepositoryProtocol: Sendable {
    func stream() -> AsyncStream<AskThread>
    func send(_ text: String, model: String) async throws
}

public actor PreviewAskRepository: AskRepositoryProtocol {
    private var thread: AskThread
    private var continuations: [UUID: AsyncStream<AskThread>.Continuation] = [:]

    public init() {
        let now = Date()
        self.thread = AskThread(
            id: "thr-1",
            title: "Quick question",
            messages: [
                .init(id: "m1", role: .assistant, content: "Hi Antonio — what can I help with? I can search across your Spotlight picks, draft reply emails, summarize a manuscript, or pull up an approval status.", createdAt: now.addingTimeInterval(-3_600), inputTokens: 0, outputTokens: 64, model: "claude-opus-4-7"),
            ],
            createdAt: now.addingTimeInterval(-3_600),
            totalInputTokens: 0,
            totalOutputTokens: 64
        )
    }

    public nonisolated func stream() -> AsyncStream<AskThread> {
        AsyncStream { continuation in
            let token = UUID()
            Task { await self.register(token: token, continuation: continuation) }
            continuation.onTermination = { _ in Task { await self.unregister(token: token) } }
        }
    }

    private func register(token: UUID, continuation: AsyncStream<AskThread>.Continuation) {
        continuations[token] = continuation
        continuation.yield(thread)
    }

    private func unregister(token: UUID) { continuations[token] = nil }

    private func emit() {
        for (_, c) in continuations { c.yield(thread) }
    }

    public func send(_ text: String, model: String) async throws {
        let now = Date()
        thread.messages.append(.init(id: UUID().uuidString, role: .user, content: text, createdAt: now))
        emit()

        try? await Task.sleep(nanoseconds: 250_000_000)

        let response = PreviewAskRepository.cannedReply(for: text)
        let messageId = UUID().uuidString
        var partial = ""
        for chunk in PreviewAskRepository.chunks(of: response) {
            partial += chunk
            if let idx = thread.messages.firstIndex(where: { $0.id == messageId }) {
                thread.messages[idx].content = partial
            } else {
                thread.messages.append(.init(id: messageId, role: .assistant, content: partial, createdAt: Date(), inputTokens: text.count / 4, outputTokens: partial.count / 4, model: model))
            }
            emit()
            try? await Task.sleep(nanoseconds: 40_000_000)
        }

        thread.totalInputTokens += text.count / 4
        thread.totalOutputTokens += response.count / 4
        emit()
    }

    static func cannedReply(for input: String) -> String {
        let needle = input.lowercased()
        if needle.contains("approval") {
            return "You have **3 pending approvals**:\n\n- Anthropic — April usage ($128.40, submitted 2d ago)\n- ICSE 2026 registration ($895.00, approved, awaiting payment)\n- Notion Team Q2 ($48.00, submitted 5d ago)\n\nThe Anthropic one is the oldest. Want me to draft a follow-up to Jacqulyn?"
        }
        if needle.contains("review") {
            return "**Active reviews (2):**\n\n1. TOSEM-2025-1266 — *A Causal Lens on Code-LLM Reasoning* — minor revision drafted, due in 5d\n2. ICSE-2026-RT-411 — *Multi-Agent Debate Improves Test Generation: A Reproducibility Study* — summarized, due in 9d\n\n**3 invitations pending** at ASE 2026, TSE, FSE 2026.\n\nWhich would you like to start with?"
        }
        if needle.contains("spotlight") || needle.contains("paper") {
            return "Today's Spotlight pick: **Towards Causal Reasoning in Code LLMs** (ICSE 2026, PICK confidence 94%). A new benchmark for evaluating causal vs. correlational reasoning in 7B code models — finds surprising chain-of-thought collapse under counterfactual prompts.\n\nWant the abstract draft for your column or the bibtex?"
        }
        return "Got it — give me a moment. (Preview repo: when wired to /api/ask, this will stream live tokens from Claude Opus 4.7. The composer, message structure, and per-message token counts are already production-shaped.)"
    }

    static func chunks(of text: String, size: Int = 24) -> [String] {
        var out: [String] = []
        var idx = text.startIndex
        while idx < text.endIndex {
            let end = text.index(idx, offsetBy: size, limitedBy: text.endIndex) ?? text.endIndex
            out.append(String(text[idx..<end]))
            idx = end
        }
        return out
    }
}
