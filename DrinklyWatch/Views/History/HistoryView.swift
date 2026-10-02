import SwiftUI
import DrinklyCore

/// Área "Histórico": hoje, ontem, últimos 7 dias, semana e mês.
struct HistoryView: View {
    @EnvironmentObject private var model: HydrationViewModel

    var body: some View {
        let service = model.service
        let today = service.today
        List {
            NavigationLink(destination: DayDetailView(service: service, day: today)) {
                HistoryMenuRow(title: "Hoje", subtitle: VolumeFormatter.progress(consumedMl: model.today.consumedMl, goalMl: model.today.goalMl), symbol: "drop.fill")
            }
            NavigationLink(destination: DayDetailView(service: service, day: today.adding(days: -1, calendar: service.calendar))) {
                HistoryMenuRow(title: "Ontem", subtitle: nil, symbol: "clock.arrow.circlepath")
            }
            NavigationLink(destination: DayListView(service: service, period: .lastDays(7))) {
                HistoryMenuRow(title: "Últimos 7 dias", subtitle: nil, symbol: "list.bullet")
            }
            NavigationLink(destination: WeekChartView(service: service)) {
                HistoryMenuRow(title: "Semana", subtitle: nil, symbol: "chart.bar.fill")
            }
            NavigationLink(destination: MonthView(service: service)) {
                HistoryMenuRow(title: "Mês", subtitle: nil, symbol: "calendar")
            }
        }
        .navigationTitle("Histórico")
    }
}

private struct HistoryMenuRow: View {
    let title: String
    let subtitle: String?
    let symbol: String

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 0) {
                Text(title).font(Theme.rounded(.body, weight: .medium))
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundColor(Theme.secondaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
        } icon: {
            Image(systemName: symbol).foregroundColor(Theme.water)
        }
    }
}
