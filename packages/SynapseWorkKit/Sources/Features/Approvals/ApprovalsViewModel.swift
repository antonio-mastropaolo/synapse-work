import Foundation
import Observation
import Models
@Observable
@MainActor
public final class ApprovalsViewModel {
    public private(set) var approvals: [Approval] = []
    public private(set) var receipts: [String: Receipt] = [:]
    public private(set) var heartbeat: DaemonHeartbeat?
    public private(set) var isLoading: Bool = false
    public private(set) var error: WorkError?
    public var statusFilter: Approval.Status? = nil

    private let repository: any ApprovalsRepositoryProtocol
    private var streamTask: Task<Void, Never>?

    public init(repository: any ApprovalsRepositoryProtocol) {
        self.repository = repository
    }

    public func start() {
        streamTask?.cancel()
        streamTask = Task { [repository] in
            for await snapshot in repository.stream() {
                await MainActor.run {
                    self.approvals = snapshot.approvals
                    self.receipts = snapshot.receipts
                    self.heartbeat = snapshot.heartbeat
                }
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
        } catch let err as WorkError {
            error = err
        } catch {
            self.error = .network(String(describing: error))
        }
    }

    public func setStatus(_ id: Approval.ID, to status: Approval.Status) async {
        let previous = approvals
        if let idx = approvals.firstIndex(where: { $0.id == id }) {
            approvals[idx].status = status
        }
        do {
            try await repository.setStatus(id: id, to: status)
        } catch {
            approvals = previous
            self.error = (error as? WorkError) ?? .network(String(describing: error))
        }
    }

    public var visibleApprovals: [Approval] {
        guard let statusFilter else { return approvals }
        return approvals.filter { $0.status == statusFilter }
    }

    public var totalsByStatus: [Approval.Status: (count: Int, cents: Int)] {
        var out: [Approval.Status: (Int, Int)] = [:]
        for a in approvals {
            let cur = out[a.status] ?? (0, 0)
            out[a.status] = (cur.0 + 1, cur.1 + a.amountCents)
        }
        return out
    }

    public var pendingCents: Int {
        approvals
            .filter { $0.status == .draft || $0.status == .submitted }
            .reduce(0) { $0 + $1.amountCents }
    }

    public var paidCents: Int {
        approvals.filter { $0.status == .paid }.reduce(0) { $0 + $1.amountCents }
    }
}
