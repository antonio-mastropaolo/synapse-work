import Foundation

public struct APISpendDay: Sendable, Identifiable, Equatable, Codable {
    public let id: String
    public let date: Date
    public let totalCents: Int
    public let perModel: [String: Int]

    public init(id: String, date: Date, totalCents: Int, perModel: [String: Int]) {
        self.id = id
        self.date = date
        self.totalCents = totalCents
        self.perModel = perModel
    }

    public var totalFormatted: String {
        (Double(totalCents) / 100.0).formatted(.currency(code: "USD"))
    }
}

public struct APISpendSummary: Sendable, Equatable, Codable {
    public let todayCents: Int
    public let mtdCents: Int
    public let forecastMonthCents: Int
    public let days: [APISpendDay]
    public let topModelToday: String?

    public init(todayCents: Int, mtdCents: Int, forecastMonthCents: Int, days: [APISpendDay], topModelToday: String?) {
        self.todayCents = todayCents
        self.mtdCents = mtdCents
        self.forecastMonthCents = forecastMonthCents
        self.days = days
        self.topModelToday = topModelToday
    }
}
