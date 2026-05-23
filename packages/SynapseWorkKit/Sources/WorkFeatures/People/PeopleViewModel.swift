import Foundation
import Observation
import WorkCore

@Observable
@MainActor
public final class PeopleViewModel {
    public private(set) var people: [Person] = []
    public private(set) var isLoading: Bool = false
    public private(set) var error: WorkError?
    public var searchText: String = ""
    public var affiliationFilter: Person.Affiliation? = nil

    private let repository: any PeopleRepositoryProtocol
    private var streamTask: Task<Void, Never>?

    public init(repository: any PeopleRepositoryProtocol) {
        self.repository = repository
    }

    public func start() {
        streamTask?.cancel()
        streamTask = Task { [repository] in
            for await batch in repository.stream() {
                await MainActor.run { self.people = batch }
            }
        }
        Task { await refresh() }
    }

    public func refresh() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await repository.refresh()
            error = nil
        } catch {
            self.error = (error as? WorkError) ?? .network(String(describing: error))
        }
    }

    public var visiblePeople: [Person] {
        var out = people
        if let aff = affiliationFilter {
            out = out.filter { $0.affiliation == aff }
        }
        if !searchText.isEmpty {
            let needle = searchText.lowercased()
            out = out.filter {
                $0.name.lowercased().contains(needle) ||
                ($0.institution?.lowercased().contains(needle) ?? false) ||
                $0.tags.contains(where: { $0.lowercased().contains(needle) })
            }
        }
        return out.sorted { $0.connectionCount > $1.connectionCount }
    }
}
