import SwiftUI
import DrinklyCore

/// Visão mensal: média, maior/menor consumo, dias com meta atingida e
/// cumprimento médio, seguida da lista de dias.
struct MonthView: View {
    @EnvironmentObject private var model: HydrationViewModel
    @StateObject private var history: HistoryViewModel

    init(service: HydrationService) {
        _history = StateObject(wrappedValue: HistoryViewModel(service: service, period: .month(service.today.monthKey)))
    }

    var body: some View {
        let stats = history.statistics
        List {
            PeriodNavigator(title: history.title,
                            canGoForward: history.canGoForward,
                            back: history.goBack,
                            forward: history.goForward)
            Section {
                StatRow(title: "Média", value: "\(VolumeFormatter.string(ml: stats.averageMl))/dia")
                StatRow(title: "Meta média", value: VolumeFormatter.string(ml: stats.averageGoalMl))
                if let highest = stats.highest {
                    StatRow(title: "Maior", value: "\(VolumeFormatter.string(ml: highest.consumedMl)) (\(HistoryViewModel.shortDate(highest.day, calendar: history.calendar)))")
                }
                if let lowest = stats.lowest {
                    StatRow(title: "Menor", value: "\(VolumeFormatter.string(ml: lowest.consumedMl)) (\(HistoryViewModel.shortDate(lowest.day, calendar: history.calendar)))")
                }
                StatRow(title: "Meta atingida", value: "\(stats.daysGoalReached) de \(stats.dayCount) dias")
                StatRow(title: "Cumprimento médio", value: "\(stats.averageCompletionPercentage)%")
            }
            Section {
                ForEach(Array(history.summaries.reversed())) { summary in
                    NavigationLink(destination: DayDetailView(service: model.service, day: summary.day)) {
                        DayBarRow(label: HistoryViewModel.shortDate(summary.day, calendar: history.calendar),
                                  summary: summary,
                                  showsVolume: true)
                    }
                }
            }
        }
        .navigationTitle("Mês")
        .onReceive(model.$dataVersion) { _ in history.load() }
    }
}
