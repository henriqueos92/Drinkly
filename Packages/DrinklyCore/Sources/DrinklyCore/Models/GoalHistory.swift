import Foundation

/// Uma alteração de meta que passa a valer a partir de `effectiveFrom`.
public struct GoalChange: Codable, Hashable, Sendable {
    public var effectiveFrom: DayKey
    public var goalMl: Int

    public init(effectiveFrom: DayKey, goalMl: Int) {
        self.effectiveFrom = effectiveFrom
        self.goalMl = goalMl
    }
}

/// Histórico de metas. Permite que dias passados sejam avaliados com a meta
/// que estava vigente naquele dia, mesmo depois que o usuário a altera.
public struct GoalHistory: Codable, Hashable, Sendable {
    public private(set) var changes: [GoalChange]

    public init(changes: [GoalChange] = []) {
        self.changes = changes.sorted { $0.effectiveFrom < $1.effectiveFrom }
    }

    /// Registra a meta para o dia informado. Se já houver uma alteração no
    /// mesmo dia, ela é substituída (o último valor do dia vale para o dia todo).
    public mutating func setGoal(_ goalMl: Int, from day: DayKey) {
        changes.removeAll { $0.effectiveFrom >= day }
        if changes.last?.goalMl == goalMl { return }
        changes.append(GoalChange(effectiveFrom: day, goalMl: goalMl))
    }

    /// Meta vigente no dia. Antes da primeira alteração, usa a mais antiga.
    public func goal(for day: DayKey) -> Int? {
        if let match = changes.last(where: { $0.effectiveFrom <= day }) {
            return match.goalMl
        }
        return changes.first?.goalMl
    }
}
