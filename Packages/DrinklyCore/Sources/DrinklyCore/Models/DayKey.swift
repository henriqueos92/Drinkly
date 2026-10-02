import Foundation

/// Identifica um dia do calendário local (ano/mês/dia), independente de horário.
///
/// O "dia atual" é sempre derivado da data local do dispositivo; por isso o
/// reset diário não depende de nenhum processo executado à meia-noite: o
/// progresso de hoje é simplesmente a soma dos registros cujo `DayKey` é hoje.
public struct DayKey: Hashable, Comparable, Codable, Sendable, CustomStringConvertible {
    public let year: Int
    public let month: Int
    public let day: Int

    public init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    public init(_ date: Date, calendar: Calendar = .current) {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        self.init(year: c.year ?? 1970, month: c.month ?? 1, day: c.day ?? 1)
    }

    /// Início (00:00) do dia no calendário informado.
    public func startDate(calendar: Calendar = .current) -> Date {
        let components = DateComponents(year: year, month: month, day: day)
        return calendar.date(from: components) ?? Date(timeIntervalSince1970: 0)
    }

    /// Intervalo [início do dia, início do dia seguinte).
    public func interval(calendar: Calendar = .current) -> DateInterval {
        let start = startDate(calendar: calendar)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start.addingTimeInterval(86_400)
        return DateInterval(start: start, end: end)
    }

    public func adding(days: Int, calendar: Calendar = .current) -> DayKey {
        let date = calendar.date(byAdding: .day, value: days, to: startDate(calendar: calendar)) ?? startDate(calendar: calendar)
        return DayKey(date, calendar: calendar)
    }

    /// Todos os dias de `start` até `end`, inclusive.
    public static func days(from start: DayKey, through end: DayKey, calendar: Calendar = .current) -> [DayKey] {
        guard start <= end else { return [] }
        var result: [DayKey] = []
        var current = start
        while current <= end {
            result.append(current)
            current = current.adding(days: 1, calendar: calendar)
        }
        return result
    }

    public var monthKey: MonthKey { MonthKey(year: year, month: month) }

    public static func < (lhs: DayKey, rhs: DayKey) -> Bool {
        (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }

    /// Formato ISO `yyyy-MM-dd`.
    public var description: String {
        String(format: "%04d-%02d-%02d", year, month, day)
    }
}

/// Identifica um mês do calendário. Também é a unidade de particionamento
/// dos arquivos de persistência (um arquivo por mês).
public struct MonthKey: Hashable, Comparable, Codable, Sendable, CustomStringConvertible {
    public let year: Int
    public let month: Int

    public init(year: Int, month: Int) {
        self.year = year
        self.month = month
    }

    public init(_ date: Date, calendar: Calendar = .current) {
        let c = calendar.dateComponents([.year, .month], from: date)
        self.init(year: c.year ?? 1970, month: c.month ?? 1)
    }

    public var firstDay: DayKey { DayKey(year: year, month: month, day: 1) }

    public func lastDay(calendar: Calendar = .current) -> DayKey {
        let start = firstDay.startDate(calendar: calendar)
        let count = calendar.range(of: .day, in: .month, for: start)?.count ?? 30
        return DayKey(year: year, month: month, day: count)
    }

    public func adding(months: Int, calendar: Calendar = .current) -> MonthKey {
        let date = calendar.date(byAdding: .month, value: months, to: firstDay.startDate(calendar: calendar)) ?? firstDay.startDate(calendar: calendar)
        return MonthKey(date, calendar: calendar)
    }

    public static func < (lhs: MonthKey, rhs: MonthKey) -> Bool {
        (lhs.year, lhs.month) < (rhs.year, rhs.month)
    }

    /// Formato `yyyy-MM`.
    public var description: String {
        String(format: "%04d-%02d", year, month)
    }
}
