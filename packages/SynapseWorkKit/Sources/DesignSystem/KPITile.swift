import SwiftUI

public struct KPITile: View {
    private let label: String
    private let value: String
    private let trend: Trend?
    private let accent: Color

    public enum Trend: Sendable, Equatable {
        case up(String)
        case down(String)
        case flat(String)

        var icon: String {
            switch self {
            case .up:   return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .flat: return "arrow.right"
            }
        }

        var text: String {
            switch self {
            case .up(let t), .down(let t), .flat(let t): return t
            }
        }

        var color: Color {
            switch self {
            case .up:   return Theme.accent
            case .down: return Theme.danger
            case .flat: return Theme.textMuted
            }
        }
    }

    public init(label: String, value: String, trend: Trend? = nil, accent: Color = Theme.textPrimary) {
        self.label = label
        self.value = value
        self.trend = trend
        self.accent = accent
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label).workUppercaseLabel(9, color: Theme.textFaint)
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(accent)
                .contentTransition(.numericText())
            if let trend {
                HStack(spacing: 4) {
                    Image(systemName: trend.icon).font(.system(size: 9, weight: .bold))
                    Text(trend.text).font(.workMono(10))
                }
                .foregroundStyle(trend.color)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Theme.surface1, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Theme.border, lineWidth: 0.5)
        )
    }
}
