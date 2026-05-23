import Foundation

public struct Person: Sendable, Identifiable, Equatable, Codable {
    public enum Affiliation: String, Sendable, Codable {
        case faculty, postdoc, phdStudent, msStudent, industry, editor, programChair, unknown

        public var label: String {
            switch self {
            case .faculty:      return "Faculty"
            case .postdoc:      return "Postdoc"
            case .phdStudent:   return "PhD Student"
            case .msStudent:    return "MS Student"
            case .industry:     return "Industry"
            case .editor:       return "Editor"
            case .programChair: return "Program Chair"
            case .unknown:      return "Unknown"
            }
        }
    }

    public let id: String
    public let name: String
    public let email: String?
    public let institution: String?
    public let affiliation: Affiliation
    public let connectionCount: Int
    public let lastInteraction: Date?
    public let tags: [String]

    public init(
        id: String,
        name: String,
        email: String?,
        institution: String?,
        affiliation: Affiliation,
        connectionCount: Int,
        lastInteraction: Date?,
        tags: [String]
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.institution = institution
        self.affiliation = affiliation
        self.connectionCount = connectionCount
        self.lastInteraction = lastInteraction
        self.tags = tags
    }
}
