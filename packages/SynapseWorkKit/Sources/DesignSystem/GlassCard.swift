import SwiftUI

public struct GlassCard<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .padding(14)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Theme.border, lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.4), radius: 24, x: 0, y: 12)
    }
}

public struct WorkBackground: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .background(Theme.background.ignoresSafeArea())
            .preferredColorScheme(.dark)
    }
}

public extension View {
    func workBackground() -> some View { modifier(WorkBackground()) }
}
