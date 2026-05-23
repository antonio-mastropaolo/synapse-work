import Foundation

public struct SpotlightEvent: Sendable, Identifiable, Equatable, Codable {
    public enum Status: String, Sendable, Codable, CaseIterable {
        case pending, acknowledged, actioned, dismissed
    }

    public enum Kind: String, Sendable, Codable {
        case pick, draftReady, network
    }

    public let id: String
    public let title: String
    public let abstract: String
    public let venue: String?
    public let detectedAt: Date
    public let kind: Kind
    public var status: Status

    public init(
        id: String,
        title: String,
        abstract: String,
        venue: String?,
        detectedAt: Date,
        kind: Kind,
        status: Status
    ) {
        self.id = id
        self.title = title
        self.abstract = abstract
        self.venue = venue
        self.detectedAt = detectedAt
        self.kind = kind
        self.status = status
    }
}
