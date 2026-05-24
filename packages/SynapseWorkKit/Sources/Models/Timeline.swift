import Foundation

public struct SilentThread: Sendable, Identifiable, Equatable, Codable {
    public let id: String
    public let counterpart: String
    public let subject: String
    public let lastTouchedAt: Date
    public let daysSilent: Int
    public let source: InboxSource

    public init(id: String, counterpart: String, subject: String, lastTouchedAt: Date, daysSilent: Int, source: InboxSource) {
        self.id = id
        self.counterpart = counterpart
        self.subject = subject
        self.lastTouchedAt = lastTouchedAt
        self.daysSilent = daysSilent
        self.source = source
    }
}

public struct ActionItem: Sendable, Identifiable, Equatable, Codable {
    public enum Priority: String, Sendable, Codable {
        case low, medium, high, urgent
    }

    public let id: String
    public let title: String
    public let context: String
    public let dueAt: Date?
    public let priority: Priority
    public let surface: String

    public init(id: String, title: String, context: String, dueAt: Date?, priority: Priority, surface: String) {
        self.id = id
        self.title = title
        self.context = context
        self.dueAt = dueAt
        self.priority = priority
        self.surface = surface
    }
}

public struct ConferenceDeadline: Sendable, Identifiable, Equatable, Codable {
    public enum Kind: String, Sendable, Codable {
        case cfp, submission, revision, cameraReady, registration, other

        public var label: String {
            switch self {
            case .cfp:          return "CFP"
            case .submission:   return "Submission"
            case .revision:     return "Revision"
            case .cameraReady:  return "Camera-Ready"
            case .registration: return "Registration"
            case .other:        return "Other"
            }
        }
    }

    public let id: String
    public let conferenceCode: String
    public let conferenceName: String
    public let kind: Kind
    public let deadline: Date
    public let location: String?
    public var dismissed: Bool

    public init(id: String, conferenceCode: String, conferenceName: String, kind: Kind, deadline: Date, location: String?, dismissed: Bool) {
        self.id = id
        self.conferenceCode = conferenceCode
        self.conferenceName = conferenceName
        self.kind = kind
        self.deadline = deadline
        self.location = location
        self.dismissed = dismissed
    }

    public var daysUntil: Int {
        Int(deadline.timeIntervalSinceNow / 86_400)
    }
}
