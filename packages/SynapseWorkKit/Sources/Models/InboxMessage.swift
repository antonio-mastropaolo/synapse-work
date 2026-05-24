import Foundation

public enum InboxTag: String, Sendable, Codable, CaseIterable {
    case review
    case approval
    case spotlight
    case meeting
    case student
    case admin
    case grant
    case travel
    case other

    public var label: String {
        switch self {
        case .review:    return "Review"
        case .approval:  return "Approval"
        case .spotlight: return "Spotlight"
        case .meeting:   return "Meeting"
        case .student:   return "Student"
        case .admin:     return "Admin"
        case .grant:     return "Grant"
        case .travel:    return "Travel"
        case .other:     return "Other"
        }
    }
}

public enum InboxSource: String, Sendable, Codable, CaseIterable {
    case gmail, outlook, calendar, slack, discord, unknown

    public var label: String {
        switch self {
        case .gmail:    return "Gmail"
        case .outlook:  return "Outlook"
        case .calendar: return "Calendar"
        case .slack:    return "Slack"
        case .discord:  return "Discord"
        case .unknown:  return "Other"
        }
    }
}

public struct InboxMessage: Sendable, Identifiable, Equatable, Codable {
    public let id: String
    public let subject: String
    public let sender: String
    public let preview: String
    public let receivedAt: Date
    public let source: InboxSource
    public let tag: InboxTag
    public var isRead: Bool
    public var isArchived: Bool

    public init(
        id: String,
        subject: String,
        sender: String,
        preview: String,
        receivedAt: Date,
        source: InboxSource,
        tag: InboxTag,
        isRead: Bool,
        isArchived: Bool
    ) {
        self.id = id
        self.subject = subject
        self.sender = sender
        self.preview = preview
        self.receivedAt = receivedAt
        self.source = source
        self.tag = tag
        self.isRead = isRead
        self.isArchived = isArchived
    }
}
