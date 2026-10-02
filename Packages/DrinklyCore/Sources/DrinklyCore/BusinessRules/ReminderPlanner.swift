import Foundation

/// Um lembrete calculado, pronto para ser agendado no sistema.
public struct PlannedReminder: Hashable, Sendable {
    public let fireDate: Date
    public let title: String
    public let body: String

    public init(fireDate: Date, title: String, body: String) {
        self.fireDate = fireDate
        self.title = title
        self.body = body
    }
}

/// Entrada do planejamento: o estado do dia no momento do cálculo.
public struct ReminderContext: Sendable {
    public var now: Date
    /// Horário da bebida mais recente de hoje (nil = nada registrado hoje).
    public var lastDrinkToday: Date?
    public var consumedTodayMl: Int
    public var goalMl: Int
    public var settings: ReminderSettings

    public init(now: Date, lastDrinkToday: Date?, consumedTodayMl: Int, goalMl: Int, settings: ReminderSettings) {
        self.now = now
        self.lastDrinkToday = lastDrinkToday
        self.consumedTodayMl = consumedTodayMl
        self.goalMl = goalMl
        self.settings = settings
    }
}

/// Regras de lembretes (puras, sem dependência de UserNotifications).
///
/// - Só lembra depois da primeira bebida do dia.
/// - O próximo lembrete é `última bebida + intervalo`; cada nova bebida
///   recalcula a sequência, então nunca há lembrete logo após beber.
/// - Respeita a janela [início, fim] configurada; nada é agendado fora dela.
/// - Agenda apenas lembretes do dia corrente: no dia seguinte, nada acontece
///   até a primeira bebida.
/// - Não há timers: o resultado é agendado com antecedência via
///   UNUserNotificationCenter, que dispara mesmo com o app fechado.
public struct ReminderPlanner: Sendable {
    /// O watchOS mantém no máximo 64 notificações pendentes por app.
    public var maxReminders: Int
    public var composer: ReminderMessageComposer

    public init(maxReminders: Int = 48, composer: ReminderMessageComposer = ReminderMessageComposer()) {
        self.maxReminders = max(maxReminders, 0)
        self.composer = composer
    }

    public func plan(for context: ReminderContext, calendar: Calendar = .current) -> [PlannedReminder] {
        let settings = context.settings
        guard settings.isEnabled, settings.hasValidWindow else { return [] }
        guard let lastDrink = context.lastDrinkToday,
              calendar.isDate(lastDrink, inSameDayAs: context.now) else { return [] }

        let progress = HydrationProgress(consumedMl: context.consumedTodayMl, goalMl: context.goalMl)
        if settings.stopWhenGoalReached && progress.goalReached { return [] }

        let dayStart = calendar.startOfDay(for: context.now)
        guard let windowStart = calendar.date(byAdding: .minute, value: settings.startMinuteOfDay, to: dayStart),
              let windowEnd = calendar.date(byAdding: .minute, value: settings.endMinuteOfDay, to: dayStart) else {
            return []
        }

        let interval = TimeInterval(settings.clampedIntervalMinutes * 60)
        var fireDates: [Date] = []
        var candidate = lastDrink.addingTimeInterval(interval)
        while candidate <= windowEnd && fireDates.count < maxReminders {
            // Antes do início da janela, o primeiro lembrete vai para o início.
            let date = max(candidate, windowStart)
            if date > context.now && fireDates.last.map({ date > $0 }) ?? true {
                fireDates.append(date)
            }
            candidate = date.addingTimeInterval(interval)
        }

        return fireDates.enumerated().map { index, date in
            let message = composer.message(
                index: index,
                progress: progress,
                minutesSinceLastDrink: Int(date.timeIntervalSince(lastDrink) / 60),
                seed: DayKey(date, calendar: calendar).day
            )
            return PlannedReminder(fireDate: date, title: message.title, body: message.body)
        }
    }

    /// Próximo lembrete previsto (nil se nenhum).
    public func nextReminderDate(for context: ReminderContext, calendar: Calendar = .current) -> Date? {
        plan(for: context, calendar: calendar).first?.fireDate
    }
}
