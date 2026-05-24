import Foundation
import Observation
import Models
@Observable
@MainActor
public final class SpotlightViewModel {
    public private(set) var events: [SpotlightEvent] = []
    public private(set) var isLoading: Bool = false
    public private(set) var error: WorkError?

    private let repository: any SpotlightRepositoryProtocol
    private var streamTask: Task<Void, Never>?

    public init(repository: any SpotlightRepositoryProtocol) {
        self.repository = repository
    }

    public func start() {
        streamTask?.cancel()
        streamTask = Task { [repository] in
            for await batch in repository.stream() {
                await MainActor.run { self.events = batch }
            }
        }
        Task { await self.refresh() }
    }

    public func refresh() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await repository.refresh()
            error = nil
        } catch let err as WorkError {
            error = err
        } catch {
            self.error = .network(String(describing: error))
        }
    }

    public func setStatus(_ id: SpotlightEvent.ID, to status: SpotlightEvent.Status) async {
        // Optimistic update.
        let previous = events
        if let idx = events.firstIndex(where: { $0.id == id }) {
            events[idx].status = status
        }
        do {
            try await repository.setStatus(id: id, to: status)
        } catch {
            events = previous
            self.error = (error as? WorkError) ?? .network(String(describing: error))
        }
    }
}
