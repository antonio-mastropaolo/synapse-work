import Foundation

public enum ReviewVerdict: String, Sendable, Codable, CaseIterable {
    case accept, minorRevision, majorRevision, reject, undecided

    public var label: String {
        switch self {
        case .accept:        return "Accept"
        case .minorRevision: return "Minor revision"
        case .majorRevision: return "Major revision"
        case .reject:        return "Reject"
        case .undecided:     return "Undecided"
        }
    }
}

public enum ReviewKind: String, Sendable, Codable {
    case journal, conference, workshop

    public var label: String {
        switch self {
        case .journal:    return "Journal"
        case .conference: return "Conference"
        case .workshop:   return "Workshop"
        }
    }
}

public struct ReviewInvitation: Sendable, Identifiable, Equatable, Codable {
    public let id: String
    public let venue: String
    public let manuscriptId: String
    public let manuscriptTitle: String
    public let invitedAt: Date
    public let deadline: Date
    public let kind: ReviewKind
    public let editor: String?

    public init(id: String, venue: String, manuscriptId: String, manuscriptTitle: String, invitedAt: Date, deadline: Date, kind: ReviewKind, editor: String?) {
        self.id = id
        self.venue = venue
        self.manuscriptId = manuscriptId
        self.manuscriptTitle = manuscriptTitle
        self.invitedAt = invitedAt
        self.deadline = deadline
        self.kind = kind
        self.editor = editor
    }
}

public struct Review: Sendable, Identifiable, Equatable, Codable {
    public enum Stage: String, Sendable, Codable {
        case fetched, summarized, judged, drafted, finalized, submitted
    }

    public let id: String
    public let venue: String
    public let manuscriptId: String
    public let manuscriptTitle: String
    public let authors: [String]
    public let deadline: Date
    public let kind: ReviewKind
    public var verdict: ReviewVerdict
    public var stage: Stage
    public var bodyMarkdown: String
    public let pageCount: Int

    public init(id: String, venue: String, manuscriptId: String, manuscriptTitle: String, authors: [String], deadline: Date, kind: ReviewKind, verdict: ReviewVerdict, stage: Stage, bodyMarkdown: String, pageCount: Int) {
        self.id = id
        self.venue = venue
        self.manuscriptId = manuscriptId
        self.manuscriptTitle = manuscriptTitle
        self.authors = authors
        self.deadline = deadline
        self.kind = kind
        self.verdict = verdict
        self.stage = stage
        self.bodyMarkdown = bodyMarkdown
        self.pageCount = pageCount
    }
}
