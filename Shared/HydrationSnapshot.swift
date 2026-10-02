import Foundation
import DrinklyCore

/// Fotografia do progresso usada por complicações (WidgetKit e ClockKit).
/// Toda a regra vem do `HydrationService`; aqui só há leitura.
struct HydrationSnapshot: Hashable {
    let date: Date
    let consumedMl: Int
    let goalMl: Int
    let quickAmountMl: Int

    var progress: HydrationProgress { HydrationProgress(consumedMl: consumedMl, goalMl: goalMl) }

    static let placeholder = HydrationSnapshot(date: Date(), consumedMl: 1250, goalMl: 2500, quickAmountMl: 300)

    /// Lê o estado atual do disco (App Group) e devolve o progresso de hoje e
    /// o "zerado" do início de amanhã — para a complicação virar o dia sozinha.
    static func loadTimeline(now: Date = Date(), calendar: Calendar = .current) -> [HydrationSnapshot] {
        let service = HydrationService(store: AppGroup.makeStore(), calendar: calendar, clock: { now })
        let goal = service.currentGoalMl()
        let quick = service.profile()?.quickAmounts.first ?? 300
        let consumed = (try? service.todaySummary().consumedMl) ?? 0
        let tomorrow = service.today.adding(days: 1, calendar: calendar).startDate(calendar: calendar)
        return [
            HydrationSnapshot(date: now, consumedMl: consumed, goalMl: goal, quickAmountMl: quick),
            HydrationSnapshot(date: tomorrow, consumedMl: 0, goalMl: goal, quickAmountMl: quick)
        ]
    }

    static func loadCurrent(now: Date = Date()) -> HydrationSnapshot {
        loadTimeline(now: now).first ?? placeholder
    }
}
