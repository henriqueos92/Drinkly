import Foundation
import DrinklyCore

/// Consultas de histórico (dia, semana, mês). Tudo é calculado a partir dos
/// registros individuais, sob demanda, então nunca há totais inconsistentes.
final class HistoryViewModel: ObservableObject {
    enum Period: Hashable {
        case day(DayKey)
        case lastDays(Int)
        case week(offset: Int)
        case month(MonthKey)
    }

    @Published private(set) var summaries: [DailySummary] = []
    @Published private(set) var statistics = PeriodStatistics(days: [])
    @Published private(set) var records: [DrinkRecord] = []
    @Published var period: Period

    private let service: HydrationService

    init(service: HydrationService, period: Period) {
        self.service = service
        self.period = period
    }

    var today: DayKey { service.today }
    var calendar: Calendar { service.calendar }

    func load() {
        let days = self.days(for: period)
        summaries = (try? service.summaries(for: days)) ?? []
        statistics = (try? service.statistics(for: days)) ?? PeriodStatistics(days: [])
        if case .day(let day) = period {
            records = ((try? service.records(on: day)) ?? []).sorted { $0.timestamp > $1.timestamp }
        }
    }

    func days(for period: Period) -> [DayKey] {
        let history = service.history
        switch period {
        case .day(let day):
            return [day]
        case .lastDays(let count):
            return history.lastDays(count, endingOn: today)
        case .week(let offset):
            return history.week(containing: today.adding(days: offset * 7, calendar: calendar))
        case .month(let month):
            return history.days(of: month, upTo: today)
        }
    }

    // MARK: - Navegação entre períodos

    var canGoForward: Bool {
        switch period {
        case .week(let offset): return offset < 0
        case .month(let month): return month < today.monthKey
        case .day(let day): return day < today
        case .lastDays: return false
        }
    }

    func goBack() { shift(by: -1) }
    func goForward() { if canGoForward { shift(by: 1) } }

    private func shift(by delta: Int) {
        switch period {
        case .week(let offset): period = .week(offset: offset + delta)
        case .month(let month): period = .month(month.adding(months: delta, calendar: calendar))
        case .day(let day): period = .day(day.adding(days: delta, calendar: calendar))
        case .lastDays: return
        }
        load()
    }

    // MARK: - Rótulos

    var title: String {
        switch period {
        case .day(let day): return Self.dayTitle(day, today: today, calendar: calendar)
        case .lastDays(let count): return "Últimos \(count) dias"
        case .week(let offset):
            if offset == 0 { return "Esta semana" }
            if offset == -1 { return "Semana passada" }
            let days = self.days(for: period)
            return "\(Self.shortDate(days.first!, calendar: calendar)) – \(Self.shortDate(days.last!, calendar: calendar))"
        case .month(let month): return Self.monthTitle(month, calendar: calendar)
        }
    }

    static func dayTitle(_ day: DayKey, today: DayKey, calendar: Calendar) -> String {
        if day == today { return "Hoje" }
        if day == today.adding(days: -1, calendar: calendar) { return "Ontem" }
        return shortDate(day, calendar: calendar)
    }

    static func shortDate(_ day: DayKey, calendar: Calendar) -> String {
        String(format: "%02d/%02d", day.day, day.month)
    }

    static func weekdayLabel(_ day: DayKey, calendar: Calendar) -> String {
        let labels = ["Dom", "Seg", "Ter", "Qua", "Qui", "Sex", "Sáb"]
        let weekday = calendar.component(.weekday, from: day.startDate(calendar: calendar))
        return labels[(weekday - 1) % 7]
    }

    static func monthTitle(_ month: MonthKey, calendar: Calendar) -> String {
        let names = ["Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho", "Julho",
                     "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro"]
        return "\(names[(month.month - 1) % 12]) \(month.year)"
    }
}
