import SwiftUI
import DrinklyCore

/// Visão semanal (segunda a domingo) em barras horizontais — o formato que
/// melhor aproveita a tela estreita do relógio.
struct WeekChartView: View {
    @EnvironmentObject private var model: HydrationViewModel
    @StateObject private var history: HistoryViewModel

    init(service: HydrationService) {
        _history = StateObject(wrappedValue: HistoryViewModel(service: service, period: .week(offset: 0)))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 6) {
                PeriodNavigator(title: history.title,
                                canGoForward: history.canGoForward,
                                back: history.goBack,
                                forward: history.goForward)
                ForEach(history.summaries) { summary in
                    DayBarRow(label: HistoryViewModel.weekdayLabel(summary.day, calendar: history.calendar),
                              summary: summary)
                        .opacity(summary.day > history.today ? 0.35 : 1)
                }
                Divider()
                StatRow(title: "Média", value: "\(VolumeFormatter.string(ml: history.statistics.averageMl))/dia")
                StatRow(title: "Meta atingida", value: "\(history.statistics.daysGoalReached) de \(history.statistics.dayCount) dias")
                StatRow(title: "Cumprimento médio", value: "\(history.statistics.averageCompletionPercentage)%")
            }
        }
        .navigationTitle("Semana")
        .onReceive(model.$dataVersion) { _ in history.load() }
    }
}
