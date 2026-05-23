import SwiftUI
import WorkCore
import WorkUI
import Observation

@Observable
@MainActor
public final class CostViewModel {
    public private(set) var summary: APISpendSummary = APISpendSummary(todayCents: 0, mtdCents: 0, forecastMonthCents: 0, days: [], topModelToday: nil)
    private let repository: any CostRepositoryProtocol
    private var streamTask: Task<Void, Never>?

    public init(repository: any CostRepositoryProtocol) { self.repository = repository }

    public func start() {
        streamTask?.cancel()
        streamTask = Task { [repository] in
            for await s in repository.stream() {
                await MainActor.run { self.summary = s }
            }
        }
        Task { try? await repository.refresh() }
    }

    public var maxCents: Int { summary.days.map { $0.totalCents }.max() ?? 1 }
}

public struct CostView: View {
    @State private var viewModel: CostViewModel

    public init(viewModel: CostViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    kpiRow
                    chart
                    breakdown
                    Spacer(minLength: 20)
                }
                .padding(16)
            }
        }
        .preferredColorScheme(.dark)
        .navigationTitle("AI Cost")
        .navigationBarTitleDisplayMode(.inline)
        .task { viewModel.start() }
    }

    private var kpiRow: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            KPITile(
                label: "Today",
                value: dollar(viewModel.summary.todayCents),
                trend: viewModel.summary.topModelToday.map { .flat($0.replacingOccurrences(of: "claude-", with: "")) },
                accent: Theme.accent
            )
            KPITile(label: "MTD", value: dollar(viewModel.summary.mtdCents), accent: Theme.cyan)
            KPITile(
                label: "Forecast",
                value: dollar(viewModel.summary.forecastMonthCents),
                trend: .up("month"),
                accent: Theme.warning
            )
        }
    }

    private var chart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("14-day spend").workUppercaseLabel(10, color: Theme.textMuted)
            GeometryReader { geo in
                let bars = viewModel.summary.days.reversed()
                let count = max(bars.count, 1)
                let barW = max((geo.size.width - CGFloat(count - 1) * 4) / CGFloat(count), 4)
                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(Array(bars.enumerated()), id: \.offset) { _, day in
                        let h = max(CGFloat(day.totalCents) / CGFloat(viewModel.maxCents) * geo.size.height, 2)
                        Rectangle()
                            .fill(LinearGradient(
                                colors: [Theme.accent, Theme.accent.opacity(0.4)],
                                startPoint: .top, endPoint: .bottom
                            ))
                            .frame(width: barW, height: h)
                            .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
                    }
                }
            }
            .frame(height: 120)
            .padding(12)
            .background(Theme.surface1, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Theme.border, lineWidth: 0.5)
            )
        }
    }

    private var breakdown: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Daily breakdown").workUppercaseLabel(10, color: Theme.textMuted)
            VStack(spacing: 6) {
                ForEach(viewModel.summary.days.prefix(7)) { day in
                    DayBreakdownRow(day: day)
                }
            }
        }
    }

    private func dollar(_ cents: Int) -> String {
        (Double(cents) / 100.0).formatted(.currency(code: "USD"))
    }
}

struct DayBreakdownRow: View {
    let day: APISpendDay

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(day.date.formatted(.dateTime.weekday(.abbreviated)))
                    .workUppercaseLabel(9, color: Theme.textFaint)
                Text(day.date.formatted(.dateTime.day().month(.abbreviated)))
                    .font(.workMono(11))
                    .foregroundStyle(Theme.textPrimary)
            }
            .frame(width: 56, alignment: .leading)
            VStack(alignment: .leading, spacing: 3) {
                ForEach(day.perModel.sorted(by: { $0.value > $1.value }), id: \.key) { entry in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(modelColor(entry.key))
                            .frame(width: 5, height: 5)
                        Text(entry.key.replacingOccurrences(of: "claude-", with: ""))
                            .font(.workMono(10))
                            .foregroundStyle(Theme.textMuted)
                        Spacer()
                        Text((Double(entry.value) / 100.0).formatted(.currency(code: "USD")))
                            .font(.workMono(10))
                            .foregroundStyle(Theme.textFaint)
                            .monospacedDigit()
                    }
                }
            }
            Spacer()
            Text(day.totalFormatted)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Theme.textPrimary)
        }
        .padding(10)
        .background(Theme.surface1, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Theme.border, lineWidth: 0.5)
        )
    }

    private func modelColor(_ model: String) -> Color {
        if model.contains("opus") { return Theme.accent }
        if model.contains("sonnet") { return Theme.cyan }
        if model.contains("haiku") { return Theme.violet }
        return Theme.textMuted
    }
}

#Preview {
    NavigationStack {
        CostView(viewModel: CostViewModel(repository: PreviewCostRepository()))
    }
}
