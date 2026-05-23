import SwiftUI

public extension Font {
    static func workTitle(_ size: CGFloat = 13) -> Font {
        .system(size: size, weight: .bold, design: .default).leading(.tight)
    }

    static func workBody(_ size: CGFloat = 13) -> Font {
        .system(size: size, weight: .regular, design: .default)
    }

    static func workMono(_ size: CGFloat = 11) -> Font {
        .system(size: size, weight: .semibold, design: .monospaced)
    }

    static func workLabel(_ size: CGFloat = 10) -> Font {
        .system(size: size, weight: .semibold, design: .monospaced)
    }
}

public extension View {
    func workUppercaseLabel(_ size: CGFloat = 11, color: Color = Theme.textFaint) -> some View {
        self
            .font(.workLabel(size))
            .tracking(size * 0.10)
            .textCase(.uppercase)
            .foregroundStyle(color)
    }
}
