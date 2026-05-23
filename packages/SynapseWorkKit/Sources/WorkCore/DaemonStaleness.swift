import Foundation

public struct DaemonHeartbeat: Sendable, Equatable {
    public let lastTick: Date

    public init(lastTick: Date) {
        self.lastTick = lastTick
    }

    public enum Severity: Sendable, Equatable {
        case fresh
        case stale(minutesElapsed: Int)
        case critical(hoursElapsed: Int)
    }

    public func severity(now: Date = .init()) -> Severity {
        let elapsed = now.timeIntervalSince(lastTick)
        if elapsed < 30 * 60 { return .fresh }
        if elapsed < 6 * 3600 {
            return .stale(minutesElapsed: Int(elapsed / 60))
        }
        return .critical(hoursElapsed: Int(elapsed / 3600))
    }
}
