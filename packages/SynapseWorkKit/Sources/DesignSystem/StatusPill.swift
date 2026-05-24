import SwiftUI

public struct StatusPill: View {
    private let label: String
    private let tint: Color
    private let size: CGFloat

    public init(label: String, tint: Color, size: CGFloat = 9) {
        self.label = label
        self.tint = tint
        self.size = size
    }

    public var body: some View {
        Text(label)
            .workUppercaseLabel(size, color: tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(tint.opacity(0.10), in: Capsule())
            .overlay(Capsule().stroke(tint.opacity(0.35), lineWidth: 0.5))
    }
}

public struct SelectablePill: View {
    private let label: String
    private let isSelected: Bool
    private let tint: Color
    private let action: () -> Void

    public init(
        label: String,
        isSelected: Bool,
        tint: Color = Theme.accent,
        action: @escaping () -> Void
    ) {
        self.label = label
        self.isSelected = isSelected
        self.tint = tint
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(label)
                .workUppercaseLabel(9, color: isSelected ? tint : Theme.textMuted)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    isSelected ? tint.opacity(0.14) : Theme.surface1,
                    in: Capsule()
                )
                .overlay(
                    Capsule().stroke(
                        isSelected ? tint.opacity(0.55) : Theme.border,
                        lineWidth: 0.5
                    )
                )
        }
        .buttonStyle(.plain)
    }
}
