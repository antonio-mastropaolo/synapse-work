import Foundation

public enum SequenceStatus: String, Sendable, Codable, CaseIterable {
    case draft, active, paused, replied, completed, bounced

    public var label: String {
        rawValue.capitalized
    }
}

public struct EmailSequence: Sendable, Identifiable, Equatable, Codable {
    public let id: String
    public let recipientName: String
    public let recipientEmail: String
    public let subject: String
    public let createdAt: Date
    public let lastTouchedAt: Date
    public var status: SequenceStatus
    public var touchCount: Int
    public var nextStepAt: Date?

    public init(
        id: String,
        recipientName: String,
        recipientEmail: String,
        subject: String,
        createdAt: Date,
        lastTouchedAt: Date,
        status: SequenceStatus,
        touchCount: Int,
        nextStepAt: Date?
    ) {
        self.id = id
        self.recipientName = recipientName
        self.recipientEmail = recipientEmail
        self.subject = subject
        self.createdAt = createdAt
        self.lastTouchedAt = lastTouchedAt
        self.status = status
        self.touchCount = touchCount
        self.nextStepAt = nextStepAt
    }
}
