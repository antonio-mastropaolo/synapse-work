import Foundation
import Observation
import Models
@Observable
@MainActor
public final class SequencesViewModel {
    public private(set) var sequences: [EmailSequence] = []
    public private(set) var isLoading: Bool = false
    public private(set) var error: WorkError?
    public var statusFilter: SequenceStatus? = nil

    private let repository: any SequencesRepositoryProtocol
    private var streamTask: Task<Void, Never>?

    public init(repository: any SequencesRepositoryProtocol) {
        self.repository = repository
    }

    public func start() {
        streamTask?.cancel()
        streamTask = Task { [repository] in
            for await batch in repository.stream() {
                await MainActor.run { self.sequences = batch }
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

    public func setStatus(_ id: EmailSequence.ID, to status: SequenceStatus) async {
        let previous = sequences
        if let idx = sequences.firstIndex(where: { $0.id == id }) {
            sequences[idx].status = status
        }
        do {
            try await repository.setStatus(id: id, to: status)
        } catch {
            sequences = previous
        }
    }

    public var visibleSequences: [EmailSequence] {
        let base = statusFilter.map { f in sequences.filter { $0.status == f } } ?? sequences
        return base.sorted { $0.lastTouchedAt > $1.lastTouchedAt }
    }

    public var activeCount: Int { sequences.filter { $0.status == .active }.count }
    public var repliedCount: Int { sequences.filter { $0.status == .replied }.count }
    public var totalTouches: Int { sequences.reduce(0) { $0 + $1.touchCount } }
    public var replyRate: Double {
        let denom = sequences.filter { $0.status != .draft && $0.status != .bounced }.count
        guard denom > 0 else { return 0 }
        return Double(repliedCount) / Double(denom)
    }
}
