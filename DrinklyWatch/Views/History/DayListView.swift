import SwiftUI
import DrinklyCore

/// Lista de dias com barras ("01/10 ████████ 2.500").
struct DayListView: View {
    @EnvironmentObject private var model: HydrationViewModel
    @StateObject private var history: HistoryViewModel

    init(service: HydrationService, period: HistoryViewModel.Period) {
        _history = StateObject(wrappedValue: HistoryViewModel(service: service, period: period))
    }

    var body: some View {
        List {
            Section {
                ForEach(Array(history.summaries.reversed())) { summary in
                    NavigationLink(destination: DayDetailView(service: model.service, day: summary.day)) {
                        DayBarRow(label: HistoryViewModel.shortDate(summary.day, calendar: history.calendar),
                                  summary: summary,
                                  showsVolume: true)
                    }
                }
            }
            Section {
                StatRow(title: "Média", value: "\(VolumeFormatter.string(ml: history.statistics.averageMl))/dia")
                StatRow(title: "Meta atingida", value: "\(history.statistics.daysGoalReached) de \(history.statistics.dayCount) dias")
                StatRow(title: "Registros", value: "\(history.statistics.recordCount)")
            }
        }
        .navigationTitle(history.title)
        .onReceive(model.$dataVersion) { _ in history.load() }
    }
}
