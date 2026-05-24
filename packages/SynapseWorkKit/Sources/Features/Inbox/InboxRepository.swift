import Foundation
import Models
public protocol InboxRepositoryProtocol: Sendable {
    func stream() -> AsyncStream<[InboxMessage]>
    func refresh() async throws
    func setRead(id: InboxMessage.ID, isRead: Bool) async throws
    func archive(id: InboxMessage.ID) async throws
}

public actor PreviewInboxRepository: InboxRepositoryProtocol {
    private var messages: [InboxMessage]
    private var continuations: [UUID: AsyncStream<[InboxMessage]>.Continuation] = [:]

    public init(messages: [InboxMessage] = PreviewInboxRepository.fixtures()) {
        self.messages = messages
    }

    public nonisolated func stream() -> AsyncStream<[InboxMessage]> {
        AsyncStream { continuation in
            let token = UUID()
            Task { await self.register(token: token, continuation: continuation) }
            continuation.onTermination = { _ in
                Task { await self.unregister(token: token) }
            }
        }
    }

    private func register(token: UUID, continuation: AsyncStream<[InboxMessage]>.Continuation) {
        continuations[token] = continuation
        continuation.yield(messages)
    }

    private func unregister(token: UUID) { continuations[token] = nil }

    public func refresh() async throws { emit() }

    public func setRead(id: InboxMessage.ID, isRead: Bool) async throws {
        guard let idx = messages.firstIndex(where: { $0.id == id }) else { return }
        messages[idx].isRead = isRead
        emit()
    }

    public func archive(id: InboxMessage.ID) async throws {
        guard let idx = messages.firstIndex(where: { $0.id == id }) else { return }
        messages[idx].isArchived = true
        emit()
    }

    private func emit() {
        for (_, continuation) in continuations { continuation.yield(messages) }
    }

    public static func fixtures() -> [InboxMessage] {
        let now = Date()
        return [
            .init(id: "msg-001", subject: "Re: TOSEM-2025-1266 — minor revision decision", sender: "ScholarOne Manuscripts", preview: "Dear Dr. Mastropaolo, we have a decision regarding your manuscript submission...", receivedAt: now.addingTimeInterval(-1_800), source: .gmail, tag: .review, isRead: false, isArchived: false),
            .init(id: "msg-002", subject: "Re: Claude API reimbursement — IT-Ticket #4429", sender: "Jacqulyn Trovato", preview: "Thanks, this is approved. I will route to AP today.", receivedAt: now.addingTimeInterval(-3_600), source: .outlook, tag: .approval, isRead: false, isArchived: false),
            .init(id: "msg-003", subject: "Office hours moved Friday → Thursday this week", sender: "Sarah Chen", preview: "Antonio, can we shift this week? I have a conflict 2-3pm Friday.", receivedAt: now.addingTimeInterval(-7_200), source: .calendar, tag: .student, isRead: true, isArchived: false),
            .init(id: "msg-004", subject: "Towards Causal Reasoning in Code LLMs — Spotlight pick", sender: "Spotlight daemon", preview: "New paper detected at ICSE 2026 matching your topic interests with 94% confidence...", receivedAt: now.addingTimeInterval(-9_400), source: .gmail, tag: .spotlight, isRead: false, isArchived: false),
            .init(id: "msg-005", subject: "ASE 2026 — PC member invitation", sender: "Lin Tan", preview: "We would be honored if you would serve on the ASE 2026 program committee...", receivedAt: now.addingTimeInterval(-86_400), source: .gmail, tag: .review, isRead: true, isArchived: false),
            .init(id: "msg-006", subject: "NSF CRII — Quarterly progress report due 6/15", sender: "NSF FastLane", preview: "This is a reminder that the quarterly progress report for award #2412341 is due...", receivedAt: now.addingTimeInterval(-86_400 * 1.2), source: .gmail, tag: .grant, isRead: true, isArchived: false),
            .init(id: "msg-007", subject: "Travel itinerary — FSE 2026 Boston", sender: "Concur", preview: "Your trip to Boston, MA has been confirmed. Departure: Aug 14 at 8:42 AM...", receivedAt: now.addingTimeInterval(-86_400 * 2), source: .outlook, tag: .travel, isRead: true, isArchived: false),
            .init(id: "msg-008", subject: "#wm-cs — Faculty meeting agenda Thursday", sender: "Andreas Stathopoulos", preview: "Hi all — here is the agenda for Thursday's meeting. Please review before...", receivedAt: now.addingTimeInterval(-86_400 * 3), source: .slack, tag: .admin, isRead: true, isArchived: false),
            .init(id: "msg-009", subject: "Yusen — proposal draft v3", sender: "Yusen Peng", preview: "Antonio, attached is the updated draft incorporating your comments from last week...", receivedAt: now.addingTimeInterval(-86_400 * 4), source: .gmail, tag: .student, isRead: true, isArchived: false),
            .init(id: "msg-010", subject: "EMSE-D-26-00412 — review #2 reminder", sender: "Editorial Manager", preview: "Dear Dr. Mastropaolo, this is a reminder that your review for manuscript EMSE-D-26-00412...", receivedAt: now.addingTimeInterval(-86_400 * 5), source: .gmail, tag: .review, isRead: false, isArchived: false),
            .init(id: "msg-011", subject: "Conference dinner reservation — Boston Aug 16", sender: "OpenTable", preview: "Confirmation for your reservation at Atlantic Fish Co on Saturday, Aug 16...", receivedAt: now.addingTimeInterval(-86_400 * 8), source: .gmail, tag: .travel, isRead: true, isArchived: false),
            .init(id: "msg-012", subject: "#paper-club — Multi-Agent Debate Improves Test Generation", sender: "Mike Ernst", preview: "Discussion thread for this week's paper. Drop your three observations by Wed evening.", receivedAt: now.addingTimeInterval(-86_400 * 9), source: .discord, tag: .other, isRead: true, isArchived: false),
            .init(id: "msg-013", subject: "Meet & greet — incoming PhD cohort 2026", sender: "Dana Wilkins", preview: "Reminder for tomorrow's intro session with the 2026 cohort, 10am, ISC 3248.", receivedAt: now.addingTimeInterval(-86_400 * 10), source: .calendar, tag: .meeting, isRead: true, isArchived: false),
        ]
    }
}
