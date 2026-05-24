import Foundation
import Models
public protocol ConferencesRepositoryProtocol: Sendable {
    func stream() -> AsyncStream<[ConferenceDeadline]>
    func refresh() async throws
    func dismiss(_ id: ConferenceDeadline.ID) async throws
    func restore(_ id: ConferenceDeadline.ID) async throws
}

public actor PreviewConferencesRepository: ConferencesRepositoryProtocol {
    private var deadlines: [ConferenceDeadline]
    private var continuations: [UUID: AsyncStream<[ConferenceDeadline]>.Continuation] = [:]

    public init() {
        self.deadlines = PreviewConferencesRepository.fixtures()
    }

    public nonisolated func stream() -> AsyncStream<[ConferenceDeadline]> {
        AsyncStream { continuation in
            let token = UUID()
            Task { await self.register(token: token, continuation: continuation) }
            continuation.onTermination = { _ in Task { await self.unregister(token: token) } }
        }
    }

    private func register(token: UUID, continuation: AsyncStream<[ConferenceDeadline]>.Continuation) {
        continuations[token] = continuation
        continuation.yield(deadlines)
    }

    private func unregister(token: UUID) { continuations[token] = nil }
    private func emit() { for (_, c) in continuations { c.yield(deadlines) } }

    public func refresh() async throws { emit() }

    public func dismiss(_ id: ConferenceDeadline.ID) async throws {
        if let idx = deadlines.firstIndex(where: { $0.id == id }) {
            deadlines[idx].dismissed = true
            emit()
        }
    }

    public func restore(_ id: ConferenceDeadline.ID) async throws {
        if let idx = deadlines.firstIndex(where: { $0.id == id }) {
            deadlines[idx].dismissed = false
            emit()
        }
    }

    static func fixtures() -> [ConferenceDeadline] {
        let now = Date()
        return [
            .init(id: "cd-1", conferenceCode: "ICSE 2026", conferenceName: "Intl Conf on Software Engineering", kind: .cameraReady, deadline: now.addingTimeInterval(86_400 * 3), location: "Vancouver, BC", dismissed: false),
            .init(id: "cd-2", conferenceCode: "ASE 2026",  conferenceName: "Automated Software Engineering", kind: .submission, deadline: now.addingTimeInterval(86_400 * 18), location: "Daejeon, KR", dismissed: false),
            .init(id: "cd-3", conferenceCode: "FSE 2026",  conferenceName: "Foundations of Software Engineering", kind: .registration, deadline: now.addingTimeInterval(86_400 * 41), location: "Boston, MA", dismissed: false),
            .init(id: "cd-4", conferenceCode: "OOPSLA 2026", conferenceName: "Object-Oriented Programming Systems & Languages", kind: .cfp, deadline: now.addingTimeInterval(86_400 * 7), location: "Athens, GR", dismissed: false),
            .init(id: "cd-5", conferenceCode: "MSR 2026",  conferenceName: "Mining Software Repositories", kind: .revision, deadline: now.addingTimeInterval(86_400 * 12), location: "Madrid, ES", dismissed: false),
            .init(id: "cd-6", conferenceCode: "ICSME 2026", conferenceName: "Intl Conf on Software Maintenance & Evolution", kind: .submission, deadline: now.addingTimeInterval(86_400 * 28), location: "Lisbon, PT", dismissed: false),
            .init(id: "cd-7", conferenceCode: "ESEC/FSE 2027", conferenceName: "European Software Engineering Conf", kind: .cfp, deadline: now.addingTimeInterval(86_400 * 92), location: "Munich, DE", dismissed: false),
            .init(id: "cd-8", conferenceCode: "POPL 2026", conferenceName: "Principles of Programming Languages", kind: .registration, deadline: now.addingTimeInterval(86_400 * 5), location: "San Diego, CA", dismissed: true),
        ]
    }
}
