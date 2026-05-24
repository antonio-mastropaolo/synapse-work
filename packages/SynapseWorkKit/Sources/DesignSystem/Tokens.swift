import Foundation
import SwiftUI

/// Cross-cutting design tokens shared with the sibling `synapse-life`
/// DesignSystem. The numbers here are intentionally identical so
/// spacing, corner radius, motion, elevation, and material vocabulary
/// stay in lockstep across the two apps; only the palette diverges
/// (see [[Theme]]). Mirrors `DesignSystemTokens.swift` in
/// `synapse-life/packages/SynapseLifeKit/Sources/DesignSystem/` —
/// update both files together.
///
/// The names are intentionally short (`DS.Spacing.lg`) because they
/// appear at every padding/spacing call site. Long names erode the
/// "use the token" reflex.
public enum DS {

    // MARK: - Spacing
    //
    // 4pt baseline grid: 4 → 8 → 12 → 16 → 24 → 32 → 48.

    public enum Spacing {
        public static let xxs:  CGFloat = 4
        public static let xs:   CGFloat = 8
        public static let sm:   CGFloat = 12
        public static let md:   CGFloat = 16
        public static let lg:   CGFloat = 24
        public static let xl:   CGFloat = 32
        public static let xxl:  CGFloat = 48
    }

    // MARK: - Corner radius
    //
    // Tuned toward the current Apple-system card language: chips and
    // controls keep a soft pill feel, cards round generously so they
    // read as floating panes rather than sharp web panels, and hero
    // surfaces sit in continuous-corner territory.

    public enum Radius {
        /// Pills, small chips. Should look "round" at any reasonable
        /// pill height.
        public static let chip:    CGFloat = 6
        /// Buttons, small inputs, status pills.
        public static let control: CGFloat = 9
        /// Default content cards / tiles.
        public static let card:    CGFloat = 16
        /// Big-canvas surfaces (modals, hero blocks).
        public static let hero:    CGFloat = 22
    }

    // MARK: - Stroke

    public enum Stroke {
        /// Hairline border for cards and subtle dividers.
        public static let hairline: CGFloat = 0.5
        /// Standard border weight on chips and buttons.
        public static let thin:     CGFloat = 1.0
        /// Emphasized — active selected row, focused inputs.
        public static let active:   CGFloat = 1.5
    }

    // MARK: - Motion
    //
    // Three named easings + one interactive spring. Use these instead
    // of inline `.easeOut(0.18)` so the entire app slows down/speeds
    // up with a single edit.

    public enum Motion {
        /// Snappy — taps, chip toggles, hover lifts. Sub-150ms.
        public static let snappy   = Animation.easeOut(duration: 0.14)
        /// Smooth — route transitions, sheet present/dismiss.
        public static let smooth   = Animation.easeInOut(duration: 0.22)
        /// Soft — empty-state crossfades, large surface swaps.
        public static let soft     = Animation.easeInOut(duration: 0.32)
        /// Spring — push gestures, drawer open. Reserved for
        /// interactive transitions, not state changes.
        public static let spring   = Animation.spring(response: 0.42, dampingFraction: 0.82)
    }

    // MARK: - Material
    //
    // System materials are the load-bearing surface treatment in the
    // current Apple aesthetic. Naming them here lets cards and chrome
    // ask for the right vibrancy level without each call site guessing.
    // The `Material` values resolve to live blur + vibrancy on device;
    // they degrade gracefully under Reduce Transparency.

    public enum Surface {
        /// Floating cards, tiles, popover bodies. The default card fill.
        public static let card: Material = .regularMaterial
        /// Lightweight chrome that should let the canvas read through —
        /// toolbars, inline chips, secondary panels.
        public static let chrome: Material = .ultraThinMaterial
        /// Heavier overlays that need to fully separate from content —
        /// modal scrims backing, sidebars over content.
        public static let raised: Material = .thickMaterial
    }

    // MARK: - Elevation
    //
    // Soft, diffuse shadow tokens. The current system look favours a
    // wide, low-opacity fall-off over a tight dark drop — depth that
    // reads as ambient light rather than a hard cast.

    public struct Shadow: Sendable {
        public let color: Color
        public let radius: CGFloat
        public let x: CGFloat
        public let y: CGFloat

        public init(color: Color, radius: CGFloat, x: CGFloat = 0, y: CGFloat = 0) {
            self.color = color
            self.radius = radius
            self.x = x
            self.y = y
        }
    }

    public enum Elevation {
        public static let none = Shadow(color: .clear, radius: 0)
        /// Card resting state — a wide, soft ambient shadow.
        public static let card = Shadow(color: Color.black.opacity(0.14), radius: 14, y: 6)
        /// Active / hovered card. Lifts further with a slightly deeper cast.
        public static let cardHover = Shadow(color: Color.black.opacity(0.22), radius: 24, y: 12)
        /// Overlays — toasts, popovers, modal cards.
        public static let overlay = Shadow(color: Color.black.opacity(0.30), radius: 40, y: 18)
    }
}

// MARK: - Convenience modifiers

public extension View {
    /// Apply a `DS.Shadow` token in one short call.
    @ViewBuilder
    func elevation(_ shadow: DS.Shadow) -> some View {
        self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
}

// MARK: - Hover-lift modifier
//
// Pairs a Button with a hover state — when the cursor enters the
// bounds, the card lifts slightly (scale + shadow). Standard
// affordance for tappable cards on macOS. Drops to a no-op on iOS
// because there's no hover.

public struct HoverLift: ViewModifier {
    let isEnabled: Bool

    @State private var isHovered = false

    public init(isEnabled: Bool = true) {
        self.isEnabled = isEnabled
    }

    public func body(content: Content) -> some View {
        content
            #if os(macOS)
            .scaleEffect(isHovered && isEnabled ? 1.01 : 1.0)
            .elevation(isHovered && isEnabled ? DS.Elevation.cardHover : DS.Elevation.card)
            .animation(DS.Motion.snappy, value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
            #else
            .elevation(DS.Elevation.card)
            #endif
    }
}

public extension View {
    /// Apply a card-style hover-lift treatment. macOS-only behaviour;
    /// iOS gets a flat shadow.
    func hoverLift(_ isEnabled: Bool = true) -> some View {
        modifier(HoverLift(isEnabled: isEnabled))
    }
}
