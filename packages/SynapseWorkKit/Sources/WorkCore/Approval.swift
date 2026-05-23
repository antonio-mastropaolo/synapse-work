import Foundation

public struct Approval: Sendable, Identifiable, Equatable, Codable {
    public enum Status: String, Sendable, Codable, CaseIterable {
        case draft, submitted, approved, paid, rejected
    }

    public enum Bucket: String, Sendable, Codable {
        case startup, nsf, travel, conference, unknown
    }

    public let id: String
    public let title: String
    public let vendor: String
    public let amountCents: Int
    public let currency: String
    public let createdAt: Date
    public let submittedAt: Date?
    public let bucket: Bucket
    public var status: Status
    public let receiptIDs: [String]
    public let worktag: String?

    public init(
        id: String,
        title: String,
        vendor: String,
        amountCents: Int,
        currency: String = "USD",
        createdAt: Date,
        submittedAt: Date?,
        bucket: Bucket,
        status: Status,
        receiptIDs: [String],
        worktag: String?
    ) {
        self.id = id
        self.title = title
        self.vendor = vendor
        self.amountCents = amountCents
        self.currency = currency
        self.createdAt = createdAt
        self.submittedAt = submittedAt
        self.bucket = bucket
        self.status = status
        self.receiptIDs = receiptIDs
        self.worktag = worktag
    }

    public var amountFormatted: String {
        let dollars = Double(amountCents) / 100.0
        return dollars.formatted(.currency(code: currency))
    }
}

public struct Receipt: Sendable, Identifiable, Equatable, Codable {
    public enum DocumentKind: String, Sendable, Codable {
        case receipt, invoice, refund, unknown
    }

    public let id: String
    public let vendor: String
    public let amountCents: Int
    public let currency: String
    public let receivedAt: Date
    public let documentKind: DocumentKind
    public let subject: String

    public init(
        id: String,
        vendor: String,
        amountCents: Int,
        currency: String = "USD",
        receivedAt: Date,
        documentKind: DocumentKind,
        subject: String
    ) {
        self.id = id
        self.vendor = vendor
        self.amountCents = amountCents
        self.currency = currency
        self.receivedAt = receivedAt
        self.documentKind = documentKind
        self.subject = subject
    }

    public var amountFormatted: String {
        let dollars = Double(amountCents) / 100.0
        return dollars.formatted(.currency(code: currency))
    }
}
