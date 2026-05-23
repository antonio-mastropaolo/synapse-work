import Foundation
import WorkCore

public protocol PeopleRepositoryProtocol: Sendable {
    func stream() -> AsyncStream<[Person]>
    func refresh() async throws
}

public actor PreviewPeopleRepository: PeopleRepositoryProtocol {
    private var people: [Person]
    private var continuations: [UUID: AsyncStream<[Person]>.Continuation] = [:]

    public init(people: [Person] = PreviewPeopleRepository.fixtures()) {
        self.people = people
    }

    public nonisolated func stream() -> AsyncStream<[Person]> {
        AsyncStream { continuation in
            let token = UUID()
            Task { await self.register(token: token, continuation: continuation) }
            continuation.onTermination = { _ in
                Task { await self.unregister(token: token) }
            }
        }
    }

    private func register(token: UUID, continuation: AsyncStream<[Person]>.Continuation) {
        continuations[token] = continuation
        continuation.yield(people)
    }

    private func unregister(token: UUID) { continuations[token] = nil }

    public func refresh() async throws {
        for (_, continuation) in continuations { continuation.yield(people) }
    }

    public static func fixtures() -> [Person] {
        let now = Date()
        return [
            .init(id: "p-001", name: "Mike Ernst", email: "mernst@cs.washington.edu", institution: "University of Washington", affiliation: .faculty, connectionCount: 42, lastInteraction: now.addingTimeInterval(-86_400 * 3), tags: ["PL", "SE", "advisor"]),
            .init(id: "p-002", name: "Lin Tan", email: "lin@purdue.edu", institution: "Purdue University", affiliation: .programChair, connectionCount: 28, lastInteraction: now.addingTimeInterval(-86_400 * 1), tags: ["ASE26", "PC"]),
            .init(id: "p-003", name: "Sarah Chen", email: "schen@wm.edu", institution: "William & Mary", affiliation: .phdStudent, connectionCount: 14, lastInteraction: now.addingTimeInterval(-3_600), tags: ["my-student", "year2"]),
            .init(id: "p-004", name: "Yusen Peng", email: "ypeng@wm.edu", institution: "William & Mary", affiliation: .phdStudent, connectionCount: 11, lastInteraction: now.addingTimeInterval(-86_400 * 4), tags: ["my-student", "year3"]),
            .init(id: "p-005", name: "Andreas Stathopoulos", email: "andreas@cs.wm.edu", institution: "William & Mary", affiliation: .faculty, connectionCount: 33, lastInteraction: now.addingTimeInterval(-86_400 * 3), tags: ["chair", "wm-cs"]),
            .init(id: "p-006", name: "Denys Poshyvanyk", email: "denys@cs.wm.edu", institution: "William & Mary", affiliation: .faculty, connectionCount: 49, lastInteraction: now.addingTimeInterval(-86_400 * 6), tags: ["mentor", "SEMERU"]),
            .init(id: "p-007", name: "Tim Menzies", email: "timm@ieee.org", institution: "NC State", affiliation: .editor, connectionCount: 21, lastInteraction: now.addingTimeInterval(-86_400 * 14), tags: ["TSE", "editor"]),
            .init(id: "p-008", name: "Reid Holmes", email: "rtholmes@cs.ubc.ca", institution: "UBC", affiliation: .faculty, connectionCount: 19, lastInteraction: now.addingTimeInterval(-86_400 * 21), tags: ["ICSE26"]),
            .init(id: "p-009", name: "Hannah Lin", email: "hlin@google.com", institution: "Google Research", affiliation: .industry, connectionCount: 8, lastInteraction: now.addingTimeInterval(-86_400 * 60), tags: ["intern-2025"]),
            .init(id: "p-010", name: "Dana Wilkins", email: "dwilkins@wm.edu", institution: "William & Mary", affiliation: .faculty, connectionCount: 17, lastInteraction: now.addingTimeInterval(-86_400 * 2), tags: ["wm-cs", "grad-coord"]),
            .init(id: "p-011", name: "Ravi Patel", email: "rpatel@wm.edu", institution: "William & Mary", affiliation: .msStudent, connectionCount: 6, lastInteraction: now.addingTimeInterval(-86_400 * 9), tags: ["my-student"]),
            .init(id: "p-012", name: "Margaret Wang", email: "mwang@anthropic.com", institution: "Anthropic", affiliation: .industry, connectionCount: 4, lastInteraction: now.addingTimeInterval(-86_400 * 18), tags: ["claude"]),
        ]
    }
}
