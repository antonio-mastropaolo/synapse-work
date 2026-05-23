import Foundation
import Observation
import WorkCore

@Observable
@MainActor
public final class TimelineViewModel {
    public private(set) var snapshot: TimelineSnapshot = TimelineSnapshot(
        silentThreads: [], actionItems: [], upcomingDeadlines: [],
        heroStats: HeroStats(unreadInbox: 0, pendingApprovals: 0, activeReviews: 0, activeSequences: 0, spotlightToday: 0, urgentDeadlines: 0),
        heartbeat: nil
    )
    public private(set) var isLoading: Bool = false
    public private(set) var error: WorkError?

    private let repository: any TimelineRepositoryProtocol
    private var streamTask: Task<Void, Never>?

    public init(repository: any TimelineRepositoryProtocol) {
        self.repository = repository
    }

    public func start() {
        streamTask?.cancel()
        streamTask = Task { [repository] in
            for await snap in repository.stream() {
                await MainActor.run { self.snapshot = snap }
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

    public func dismiss(_ id: ConferenceDeadline.ID) async {
        do {
            try await repository.dismissDeadline(id)
        } catch {
            self.error = (error as? WorkError) ?? .network(String(describing: error))
        }
    }
}
