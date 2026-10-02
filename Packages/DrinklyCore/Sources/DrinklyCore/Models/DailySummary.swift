import Foundation

/// Situação do dia em relação à meta.
public enum GoalStatus: String, Sendable {
    /// Nenhum consumo registrado.
    case empty
    case inProgress
    /// Exatamente na meta (consumo == meta).
    case reached
    /// Acima da meta.
    case exceeded
}

/// Agregado calculado de um dia. Nunca é persistido: é sempre derivado dos
/// registros individuais.
public struct DailySummary: Hashable, Identifiable, Sendable {
    public let day: DayKey
    public let consumedMl: Int
    public let goalMl: Int
    public let recordCount: Int

    public var id: DayKey { day }

    public init(day: DayKey, consumedMl: Int, goalMl: Int, recordCount: Int) {
        self.day = day
        self.consumedMl = consumedMl
        self.goalMl = goalMl
        self.recordCount = recordCount
    }

    public var progress: HydrationProgress {
        HydrationProgress(consumedMl: consumedMl, goalMl: goalMl)
    }

    public var percentage: Int { progress.percentage }
    public var remainingMl: Int { progress.remainingMl }
    public var goalReached: Bool { progress.goalReached }
    public var status: GoalStatus { progress.status }
}
