import Foundation

public struct AskMessage: Sendable, Identifiable, Equatable, Codable {
    public enum Role: String, Sendable, Codable {
        case user, assistant, system
    }

    public let id: String
    public let role: Role
    public var content: String
    public let createdAt: Date
    public let inputTokens: Int?
    public let outputTokens: Int?
    public let model: String?

    public init(id: String, role: Role, content: String, createdAt: Date, inputTokens: Int? = nil, outputTokens: Int? = nil, model: String? = nil) {
        self.id = id
        self.role = role
        self.content = content
        self.createdAt = createdAt
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.model = model
    }
}

public struct AskThread: Sendable, Identifiable, Equatable, Codable {
    public let id: String
    public let title: String
    public var messages: [AskMessage]
    public let createdAt: Date
    public var totalInputTokens: Int
    public var totalOutputTokens: Int

    public init(id: String, title: String, messages: [AskMessage], createdAt: Date, totalInputTokens: Int, totalOutputTokens: Int) {
        self.id = id
        self.title = title
        self.messages = messages
        self.createdAt = createdAt
        self.totalInputTokens = totalInputTokens
        self.totalOutputTokens = totalOutputTokens
    }
}
