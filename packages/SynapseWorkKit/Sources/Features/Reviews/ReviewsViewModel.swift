import Foundation
import Observation
import Models
@Observable
@MainActor
public final class ReviewsViewModel {
    public private(set) var snapshot = ReviewsSnapshot(invitations: [], active: [], archived: [])
    public private(set) var isLoading = false
    public private(set) var error: WorkError?
    public var section: Section = .invitations

    public enum Section: String, CaseIterable, Hashable, Sendable {
        case invitations, active, archive
        public var label: String { rawValue.capitalized }
    }

    private let repository: any ReviewsRepositoryProtocol
    private var streamTask: Task<Void, Never>?

    public init(repository: any ReviewsRepositoryProtocol) {
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

    public func accept(_ id: ReviewInvitation.ID) async {
        try? await repository.acceptInvitation(id)
    }

    public func decline(_ id: ReviewInvitation.ID) async {
        try? await repository.declineInvitation(id)
    }

    public func setVerdict(_ id: Review.ID, _ verdict: ReviewVerdict) async {
        try? await repository.updateVerdict(id, verdict: verdict)
    }

    public func updateBody(_ id: Review.ID, _ body: String) async {
        try? await repository.updateBody(id, body: body)
    }
}
