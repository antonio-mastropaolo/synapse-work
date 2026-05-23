import SwiftUI

public enum Theme {
    public static let background = Color(red: 0.031, green: 0.031, blue: 0.063)
    public static let surface1 = Color.white.opacity(0.04)
    public static let surface2 = Color.white.opacity(0.08)
    public static let border = Color.white.opacity(0.06)
    public static let borderStrong = Color.white.opacity(0.12)

    public static let accent = Color(red: 0.0, green: 1.0, blue: 0.616)         // #00ff9d neon
    public static let signalGlow = Color(red: 0.067, green: 0.341, blue: 0.251)  // #115740 W&M
    public static let warning = Color(red: 1.0, green: 0.478, blue: 0.0)         // #ff7a00
    public static let cyan = Color(red: 0.0, green: 0.898, blue: 1.0)            // #00e5ff
    public static let violet = Color(red: 0.659, green: 0.333, blue: 0.969)      // #a855f7
    public static let danger = Color(red: 1.0, green: 0.42, blue: 0.541)         // #ff6b8a

    public static let textPrimary = Color(red: 0.98, green: 0.98, blue: 1.0)
    public static let textMuted = Color(red: 0.627, green: 0.627, blue: 0.69)
    public static let textFaint = Color(red: 0.478, green: 0.478, blue: 0.541)
}

public enum SourceColor: String, Sendable {
    case gmail, calendar, slack, outlook, discord, unknown

    public var swiftUIColor: Color {
        switch self {
        case .gmail:    return Color(red: 0.918, green: 0.263, blue: 0.208)
        case .calendar: return Color(red: 0.231, green: 0.510, blue: 0.965)
        case .slack:    return Color(red: 0.435, green: 0.294, blue: 0.839)
        case .outlook:  return Color(red: 0.180, green: 0.439, blue: 0.910)
        case .discord:  return Color(red: 0.345, green: 0.396, blue: 0.949)
        case .unknown:  return Theme.border
        }
    }
}
