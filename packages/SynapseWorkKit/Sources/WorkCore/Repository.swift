import Foundation

public protocol Repository: Sendable {
    associatedtype Entity: Sendable & Identifiable

    func stream() -> AsyncStream<[Entity]>
    func refresh() async throws
}

public protocol MutableRepository: Repository {
    associatedtype Mutation: Sendable
    func apply(_ mutation: Mutation) async throws
}
