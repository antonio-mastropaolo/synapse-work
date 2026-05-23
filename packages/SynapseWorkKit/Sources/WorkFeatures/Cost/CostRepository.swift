import Foundation
import WorkCore

public protocol CostRepositoryProtocol: Sendable {
    func stream() -> AsyncStream<APISpendSummary>
    func refresh() async throws
}

public actor PreviewCostRepository: CostRepositoryProtocol {
    private var summary: APISpendSummary
    private var continuations: [UUID: AsyncStream<APISpendSummary>.Continuation] = [:]

    public init() {
        self.summary = PreviewCostRepository.fixture()
    }

    public nonisolated func stream() -> AsyncStream<APISpendSummary> {
        AsyncStream { continuation in
            let token = UUID()
            Task { await self.register(token: token, continuation: continuation) }
            continuation.onTermination = { _ in Task { await self.unregister(token: token) } }
        }
    }

    private func register(token: UUID, continuation: AsyncStream<APISpendSummary>.Continuation) {
        continuations[token] = continuation
        continuation.yield(summary)
    }

    private func unregister(token: UUID) { continuations[token] = nil }

    public func refresh() async throws { for (_, c) in continuations { c.yield(summary) } }

    static func fixture() -> APISpendSummary {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let days: [APISpendDay] = (0..<14).map { i in
            let date = cal.date(byAdding: .day, value: -i, to: today)!
            let base = Int.random(in: 180...640)
            let opus = Int(Double(base) * 0.75)
            let sonnet = Int(Double(base) * 0.18)
            let haiku = base - opus - sonnet
            return APISpendDay(
                id: "spend-\(i)",
                date: date,
                totalCents: base * 4,
                perModel: [
                    "claude-opus-4-7": opus * 4,
                    "claude-sonnet-4-6": sonnet * 4,
                    "claude-haiku-4-5": haiku * 4
                ]
            )
        }
        let todayCents = days.first?.totalCents ?? 0
        let mtdCents = days.prefix(Calendar.current.component(.day, from: Date())).reduce(0) { $0 + $1.totalCents }
        let avgDaily = mtdCents / max(1, days.prefix(Calendar.current.component(.day, from: Date())).count)
        let forecast = avgDaily * 30
        return APISpendSummary(
            todayCents: todayCents,
            mtdCents: mtdCents,
            forecastMonthCents: forecast,
            days: days,
            topModelToday: "claude-opus-4-7"
        )
    }
}
