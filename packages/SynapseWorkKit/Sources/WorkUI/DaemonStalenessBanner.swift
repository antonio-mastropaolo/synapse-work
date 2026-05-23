import SwiftUI
import WorkCore

public struct DaemonStalenessBanner: View {
    private let heartbeat: DaemonHeartbeat?
    private let onRefresh: () -> Void

    public init(heartbeat: DaemonHeartbeat?, onRefresh: @escaping () -> Void) {
        self.heartbeat = heartbeat
        self.onRefresh = onRefresh
    }

    public var body: some View {
        if let heartbeat, let severity = renderableSeverity(for: heartbeat) {
            HStack(spacing: 10) {
                Circle()
                    .fill(severity.tint)
                    .frame(width: 6, height: 6)
                VStack(alignment: .leading, spacing: 2) {
                    Text(severity.title)
                        .workUppercaseLabel(10, color: severity.tint)
                    Text(severity.detail)
                        .font(.workMono(11))
                        .foregroundStyle(Theme.textMuted)
                }
                Spacer()
                Button(action: onRefresh) {
                    Text("Refresh")
                        .workUppercaseLabel(10, color: severity.tint)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(severity.tint.opacity(0.12), in: Capsule())
                        .overlay(Capsule().stroke(severity.tint.opacity(0.5), lineWidth: 0.5))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.thinMaterial)
            .overlay(
                Rectangle()
                    .fill(Theme.border)
                    .frame(height: 0.5),
                alignment: .bottom
            )
        }
    }

    private struct Renderable {
        let title: String
        let detail: String
        let tint: Color
    }

    private func renderableSeverity(for heartbeat: DaemonHeartbeat) -> Renderable? {
        switch heartbeat.severity() {
        case .fresh:
            return nil
        case .stale(let minutes):
            return Renderable(
                title: "Sync paused",
                detail: "Last update \(minutes)m ago",
                tint: Theme.warning
            )
        case .critical(let hours):
            return Renderable(
                title: "Daemon offline",
                detail: "Last update \(hours)h ago — mutations disabled",
                tint: Theme.danger
            )
        }
    }
}
