import Foundation

/// Estatísticas de um período (semana, mês, últimos N dias).
public struct PeriodStatistics: Hashable, Sendable {
    public let days: [DailySummary]

    public init(days: [DailySummary]) {
        self.days = days
    }

    public var dayCount: Int { days.count }
    public var totalMl: Int { days.reduce(0) { $0 + $1.consumedMl } }
    public var recordCount: Int { days.reduce(0) { $0 + $1.recordCount } }

    public var averageMl: Int {
        guard !days.isEmpty else { return 0 }
        return Int((Double(totalMl) / Double(days.count)).rounded())
    }

    public var averageGoalMl: Int {
        guard !days.isEmpty else { return 0 }
        return Int((Double(days.reduce(0) { $0 + $1.goalMl }) / Double(days.count)).rounded())
    }

    public var highest: DailySummary? {
        days.max { ($0.consumedMl, $1.day) < ($1.consumedMl, $0.day) }
    }

    public var lowest: DailySummary? {
        days.min { ($0.consumedMl, $0.day) < ($1.consumedMl, $1.day) }
    }

    public var daysGoalReached: Int { days.filter(\.goalReached).count }

    /// Média do percentual de cumprimento (cada dia limitado a 100% para que
    /// um único dia excedido não mascare dias fracos).
    public var averageCompletionPercentage: Int {
        guard !days.isEmpty else { return 0 }
        let sum = days.reduce(0.0) { $0 + min($1.progress.fraction, 1) }
        return Int((sum / Double(days.count) * 100).rounded())
    }
}

/// Agrega registros em resumos diários. Puro: recebe tudo por parâmetro.
public struct HistoryCalculator: Sendable {
    public var calendar: Calendar

    public init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    /// Resumo de cada dia em `days`, mesmo os sem registros (consumo 0).
    /// - Parameter goalForDay: meta vigente em cada dia.
    public func summaries(for days: [DayKey], records: [DrinkRecord], goalForDay: (DayKey) -> Int) -> [DailySummary] {
        var totals: [DayKey: (ml: Int, count: Int)] = [:]
        for record in records {
            let key = record.day(calendar: calendar)
            let current = totals[key] ?? (0, 0)
            totals[key] = (current.ml + record.volumeMl, current.count + 1)
        }
        return days.map { day in
            let total = totals[day] ?? (0, 0)
            return DailySummary(day: day, consumedMl: total.ml, goalMl: goalForDay(day), recordCount: total.count)
        }
    }

    /// Dias da semana (segunda a domingo, padrão brasileiro/ISO) que contém `day`.
    public func week(containing day: DayKey) -> [DayKey] {
        let date = day.startDate(calendar: calendar)
        let weekday = calendar.component(.weekday, from: date) // 1 = domingo
        let offsetFromMonday = (weekday + 5) % 7
        let monday = day.adding(days: -offsetFromMonday, calendar: calendar)
        return (0..<7).map { monday.adding(days: $0, calendar: calendar) }
    }

    /// Últimos `count` dias terminando em `day` (inclusive), do mais antigo ao mais recente.
    public func lastDays(_ count: Int, endingOn day: DayKey) -> [DayKey] {
        guard count > 0 else { return [] }
        return DayKey.days(from: day.adding(days: -(count - 1), calendar: calendar), through: day, calendar: calendar)
    }

    /// Dias do mês até `today` (para o mês corrente) ou o mês inteiro.
    public func days(of month: MonthKey, upTo today: DayKey) -> [DayKey] {
        let last = min(month.lastDay(calendar: calendar), today)
        return DayKey.days(from: month.firstDay, through: last, calendar: calendar)
    }
}
