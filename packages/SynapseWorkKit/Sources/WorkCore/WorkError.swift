import Foundation

public enum WorkError: Error, Sendable, Equatable {
    case unauthenticated
    case network(String)
    case decoding(String)
    case server(status: Int, message: String?)
    case offline
    case daemonStale(lastTick: Date)
}
