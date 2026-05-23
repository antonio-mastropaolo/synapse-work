import Foundation
import Observation
import WorkCore

@Observable
@MainActor
public final class InboxViewModel {
    public private(set) var messages: [InboxMessage] = []
    public private(set) var isLoading: Bool = false
    public private(set) var error: WorkError?
    public var searchText: String = ""
    public var scope: InboxScope = .all

    public enum InboxScope: Hashable, Sendable {
        case all
        case tag(InboxTag)

        public var label: String {
            switch self {
            case .all: return "All"
            case .tag(let t): return t.label
            }
        }
    }

    private let repository: any InboxRepositoryProtocol
    private var streamTask: Task<Void, Never>?

    public init(repository: any InboxRepositoryProtocol) {
        self.repository = repository
    }

    public func start() {
        streamTask?.cancel()
        streamTask = Task { [repository] in
            for await batch in repository.stream() {
                await MainActor.run { self.messages = batch }
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

    public func archive(_ id: InboxMessage.ID) async {
        let previous = messages
        if let idx = messages.firstIndex(where: { $0.id == id }) {
            messages[idx].isArchived = true
        }
        do {
            try await repository.archive(id: id)
        } catch {
            messages = previous
        }
    }

    public func markRead(_ id: InboxMessage.ID, isRead: Bool) async {
        let previous = messages
        if let idx = messages.firstIndex(where: { $0.id == id }) {
            messages[idx].isRead = isRead
        }
        do {
            try await repository.setRead(id: id, isRead: isRead)
        } catch {
            messages = previous
        }
    }

    public var visibleMessages: [InboxMessage] {
        let base = messages.filter { !$0.isArchived }
        let scoped: [InboxMessage]
        switch scope {
        case .all: scoped = base
        case .tag(let t): scoped = base.filter { $0.tag == t }
        }
        guard !searchText.isEmpty else { return scoped }
        let needle = searchText.lowercased()
        return scoped.filter {
            $0.subject.lowercased().contains(needle) ||
            $0.sender.lowercased().contains(needle) ||
            $0.preview.lowercased().contains(needle)
        }
    }

    public var unreadCount: Int { messages.lazy.filter { !$0.isRead && !$0.isArchived }.count }

    public struct TimeBand: Sendable, Hashable {
        public let title: String
        public let lowerBound: Date
        public let upperBound: Date
    }

    public func groupedByBand(now: Date = .init()) -> [(band: String, items: [InboxMessage])] {
        let cal = Calendar.current
        let todayStart = cal.startOfDay(for: now)
        let yesterdayStart = cal.date(byAdding: .day, value: -1, to: todayStart)!
        let weekStart = cal.date(byAdding: .day, value: -7, to: todayStart)!

        var bands: [String: [InboxMessage]] = [:]
        for m in visibleMessages {
            let key: String
            if m.receivedAt >= todayStart { key = "Today" }
            else if m.receivedAt >= yesterdayStart { key = "Yesterday" }
            else if m.receivedAt >= weekStart { key = "This week" }
            else { key = "Older" }
            bands[key, default: []].append(m)
        }
        let order = ["Today", "Yesterday", "This week", "Older"]
        return order.compactMap { name in
            guard let items = bands[name], !items.isEmpty else { return nil }
            return (band: name, items: items.sorted { $0.receivedAt > $1.receivedAt })
        }
    }
}
