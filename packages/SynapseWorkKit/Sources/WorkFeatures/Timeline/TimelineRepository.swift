import Foundation
import WorkCore

public protocol TimelineRepositoryProtocol: Sendable {
    func stream() -> AsyncStream<TimelineSnapshot>
    func refresh() async throws
    func dismissDeadline(_ id: ConferenceDeadline.ID) async throws
}

public struct TimelineSnapshot: Sendable, Equatable {
    public let silentThreads: [SilentThread]
    public let actionItems: [ActionItem]
    public let upcomingDeadlines: [ConferenceDeadline]
    public let heroStats: HeroStats
    public let heartbeat: DaemonHeartbeat?

    public init(silentThreads: [SilentThread], actionItems: [ActionItem], upcomingDeadlines: [ConferenceDeadline], heroStats: HeroStats, heartbeat: DaemonHeartbeat?) {
        self.silentThreads = silentThreads
        self.actionItems = actionItems
        self.upcomingDeadlines = upcomingDeadlines
        self.heroStats = heroStats
        self.heartbeat = heartbeat
    }
}

public struct HeroStats: Sendable, Equatable {
    public let unreadInbox: Int
    public let pendingApprovals: Int
    public let activeReviews: Int
    public let activeSequences: Int
    public let spotlightToday: Int
    public let urgentDeadlines: Int

    public init(unreadInbox: Int, pendingApprovals: Int, activeReviews: Int, activeSequences: Int, spotlightToday: Int, urgentDeadlines: Int) {
        self.unreadInbox = unreadInbox
        self.pendingApprovals = pendingApprovals
        self.activeReviews = activeReviews
        self.activeSequences = activeSequences
        self.spotlightToday = spotlightToday
        self.urgentDeadlines = urgentDeadlines
    }
}

public actor PreviewTimelineRepository: TimelineRepositoryProtocol {
    private var snapshot: TimelineSnapshot
    private var continuations: [UUID: AsyncStream<TimelineSnapshot>.Continuation] = [:]

    public init() {
        self.snapshot = PreviewTimelineRepository.fixture()
    }

    public nonisolated func stream() -> AsyncStream<TimelineSnapshot> {
        AsyncStream { continuation in
            let token = UUID()
            Task { await self.register(token: token, continuation: continuation) }
            continuation.onTermination = { _ in
                Task { await self.unregister(token: token) }
            }
        }
    }

    private func register(token: UUID, continuation: AsyncStream<TimelineSnapshot>.Continuation) {
        continuations[token] = continuation
        continuation.yield(snapshot)
    }

    private func unregister(token: UUID) { continuations[token] = nil }

    public func refresh() async throws {
        for (_, c) in continuations { c.yield(snapshot) }
    }

    public func dismissDeadline(_ id: ConferenceDeadline.ID) async throws {
        var deadlines = snapshot.upcomingDeadlines
        if let idx = deadlines.firstIndex(where: { $0.id == id }) {
            deadlines[idx].dismissed = true
        }
        snapshot = TimelineSnapshot(
            silentThreads: snapshot.silentThreads,
            actionItems: snapshot.actionItems,
            upcomingDeadlines: deadlines,
            heroStats: snapshot.heroStats,
            heartbeat: snapshot.heartbeat
        )
        for (_, c) in continuations { c.yield(snapshot) }
    }

    static func fixture() -> TimelineSnapshot {
        let now = Date()
        return TimelineSnapshot(
            silentThreads: [
                .init(id: "st-1", counterpart: "Tim Menzies", subject: "TSE special issue — code-LLM eval", lastTouchedAt: now.addingTimeInterval(-86_400 * 10), daysSilent: 10, source: .gmail),
                .init(id: "st-2", counterpart: "Brad Myers", subject: "PL/SE intersection — survey co-author", lastTouchedAt: now.addingTimeInterval(-86_400 * 14), daysSilent: 14, source: .gmail),
                .init(id: "st-3", counterpart: "Reid Holmes", subject: "Collaboration — code-LLM benchmarks", lastTouchedAt: now.addingTimeInterval(-86_400 * 5), daysSilent: 5, source: .outlook),
                .init(id: "st-4", counterpart: "Hannah Lin (Google)", subject: "Coffee at FSE? Boston Aug 15-18", lastTouchedAt: now.addingTimeInterval(-86_400 * 3), daysSilent: 3, source: .gmail),
            ],
            actionItems: [
                .init(id: "ai-1", title: "Submit ICSE 2026 camera-ready", context: "Track 1 paper — Yusen", dueAt: now.addingTimeInterval(86_400 * 3), priority: .urgent, surface: "Conferences"),
                .init(id: "ai-2", title: "Review TOSEM-2025-1266", context: "Editor: Tim Menzies", dueAt: now.addingTimeInterval(86_400 * 5), priority: .high, surface: "Reviews"),
                .init(id: "ai-3", title: "Submit Anthropic April reimbursement", context: "Approval still in draft", dueAt: now.addingTimeInterval(86_400 * 2), priority: .high, surface: "Approvals"),
                .init(id: "ai-4", title: "Reply to Lin Tan re: ASE26 PC", context: "Inbox · 1 day silent", dueAt: now.addingTimeInterval(86_400 * 1), priority: .medium, surface: "Inbox"),
                .init(id: "ai-5", title: "NSF CRII quarterly report", context: "Due 2026-06-15", dueAt: now.addingTimeInterval(86_400 * 22), priority: .medium, surface: "Grants"),
            ],
            upcomingDeadlines: [
                .init(id: "d-1", conferenceCode: "ICSE 2026", conferenceName: "Intl Conf on Software Engineering", kind: .cameraReady, deadline: now.addingTimeInterval(86_400 * 3), location: "Vancouver, BC", dismissed: false),
                .init(id: "d-2", conferenceCode: "ASE 2026",  conferenceName: "Automated Software Engineering", kind: .submission, deadline: now.addingTimeInterval(86_400 * 18), location: "Daejeon, KR", dismissed: false),
                .init(id: "d-3", conferenceCode: "FSE 2026",  conferenceName: "Foundations of Software Engineering", kind: .registration, deadline: now.addingTimeInterval(86_400 * 41), location: "Boston, MA", dismissed: false),
                .init(id: "d-4", conferenceCode: "OOPSLA 2026", conferenceName: "Object-Oriented Programming Systems, Languages", kind: .cfp, deadline: now.addingTimeInterval(86_400 * 7), location: "Athens, GR", dismissed: false),
                .init(id: "d-5", conferenceCode: "MSR 2026",  conferenceName: "Mining Software Repositories", kind: .revision, deadline: now.addingTimeInterval(86_400 * 12), location: "Madrid, ES", dismissed: false),
            ],
            heroStats: HeroStats(
                unreadInbox: 4,
                pendingApprovals: 3,
                activeReviews: 2,
                activeSequences: 3,
                spotlightToday: 1,
                urgentDeadlines: 2
            ),
            heartbeat: DaemonHeartbeat(lastTick: Date().addingTimeInterval(-180))
        )
    }
}
