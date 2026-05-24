import Foundation
import Observation
import Models
@Observable
@MainActor
public final class AskViewModel {
    public private(set) var thread: AskThread = AskThread(id: "thr-0", title: "", messages: [], createdAt: .init(), totalInputTokens: 0, totalOutputTokens: 0)
    public private(set) var isSending = false
    public var composer: String = ""
    public var model: String = "claude-opus-4-7"
    public let availableModels: [String] = ["claude-opus-4-7", "claude-sonnet-4-6", "claude-haiku-4-5"]

    private let repository: any AskRepositoryProtocol
    private var streamTask: Task<Void, Never>?

    public init(repository: any AskRepositoryProtocol) {
        self.repository = repository
    }

    public func start() {
        streamTask?.cancel()
        streamTask = Task { [repository] in
            for await t in repository.stream() {
                await MainActor.run { self.thread = t }
            }
        }
    }

    public func send() async {
        let text = composer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isSending else { return }
        composer = ""
        isSending = true
        defer { isSending = false }
        try? await repository.send(text, model: model)
    }

    public var spendCents: Int {
        let inCost = Double(thread.totalInputTokens) * 0.000_015 * 100 // $15/M input → cents
        let outCost = Double(thread.totalOutputTokens) * 0.000_075 * 100 // $75/M output → cents
        return Int((inCost + outCost).rounded())
    }

    public var spendFormatted: String {
        let dollars = Double(spendCents) / 100.0
        return dollars.formatted(.currency(code: "USD").precision(.fractionLength(4)))
    }
}
