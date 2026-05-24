import SwiftUI

/// Palette and surface tokens for the work app.
///
/// The token surface here is parallel to the sibling `synapse-life`
/// DesignSystem so a feature port can resolve the same semantic name
/// (`Theme.textPrimary`, `Theme.divider`, `Theme.success`) on either
/// side. Identity-defining values — the neon accent, the W&M
/// `signalGlow`, the blue-violet `background` — are intentionally
/// work-specific and do not mirror life's gold-on-graphite. The
/// neutral text and divider tokens DO mirror life's values so chrome
/// reads as one design language across the two apps.
///
/// Color statics are `let` constants of the value-type `Color`, which
/// is implicitly `Sendable`; the namespace stays compatible with
/// Swift 6 strict concurrency without requiring an explicit
/// annotation on the enum itself.
public enum Theme {
    // MARK: - Surfaces

    public static let background = Color(red: 0.031, green: 0.031, blue: 0.063)
    public static let surface1 = Color.white.opacity(0.04)
    public static let surface2 = Color.white.opacity(0.08)
    public static let border = Color.white.opacity(0.06)
    public static let borderStrong = Color.white.opacity(0.12)
    /// Hairline divider token — aliased to the sibling life app's
    /// `CopilotTokens.shell.separator` value so list separators and
    /// inline rules read identically across the two apps.
    public static let divider = Color.white.opacity(0.10)

    // MARK: - Brand & semantic accents

    public static let accent = Color(red: 0.0, green: 1.0, blue: 0.616)         // #00ff9d neon
    public static let signalGlow = Color(red: 0.067, green: 0.341, blue: 0.251)  // #115740 W&M
    public static let warning = Color(red: 1.0, green: 0.478, blue: 0.0)         // #ff7a00
    public static let cyan = Color(red: 0.0, green: 0.898, blue: 1.0)            // #00e5ff
    public static let violet = Color(red: 0.659, green: 0.333, blue: 0.969)      // #a855f7
    public static let danger = Color(red: 1.0, green: 0.42, blue: 0.541)         // #ff6b8a
    /// Positive / gain semantic. Maps to the brand neon `accent`; the
    /// alias exists so a port from synapse-life can write
    /// `Theme.success` without reaching for the work brand mark.
    public static let success = accent

    // MARK: - Text

    public static let textPrimary = Color(red: 0.98, green: 0.98, blue: 1.0)
    public static let textMuted = Color(red: 0.627, green: 0.627, blue: 0.69)
    /// Parallel name for `textMuted`. The life app exposes
    /// `foregroundSecondary` / `textSecondary`; carry the same name
    /// here so the call sites match.
    public static let textSecondary = textMuted
    /// Sits between `textMuted` and `textFaint`. Introduced for macOS sidebar
    /// section headers where `textFaint` reads too washed-out against the
    /// vibrant material background. Reusable on iOS as well — keep
    /// platform-shared tokens here per ground-rule #2.
    public static let textTertiary = Color(red: 0.553, green: 0.553, blue: 0.616)
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
