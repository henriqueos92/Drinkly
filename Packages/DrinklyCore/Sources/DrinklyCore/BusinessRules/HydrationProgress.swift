import Foundation

/// Matemática do progresso diário. Não limita o consumo a 100%: o valor real
/// é sempre preservado e a interface decide como representar o excedente.
public struct HydrationProgress: Hashable, Sendable {
    public let consumedMl: Int
    public let goalMl: Int

    public init(consumedMl: Int, goalMl: Int) {
        self.consumedMl = max(consumedMl, 0)
        self.goalMl = max(goalMl, 0)
    }

    /// Fração consumida (0...∞). 1.0 = meta. Meta zero conta como cumprida.
    public var fraction: Double {
        guard goalMl > 0 else { return consumedMl > 0 ? 1 : 0 }
        return Double(consumedMl) / Double(goalMl)
    }

    /// Fração limitada a 0...1, útil para preencher barras e o avatar.
    public var clampedFraction: Double { min(max(fraction, 0), 1) }

    /// Percentual arredondado. Enquanto a meta não é atingida o valor máximo
    /// exibido é 99%, para nunca mostrar "100%" antes do tempo
    /// (ex.: 2.490 / 2.500 ml → 99%, e não 100%).
    public var percentage: Int {
        let rounded = Int((fraction * 100).rounded())
        return goalReached ? max(rounded, 100) : min(rounded, 99)
    }

    /// Quanto falta para a meta (nunca negativo).
    public var remainingMl: Int { max(goalMl - consumedMl, 0) }

    /// Quanto passou da meta (0 se não passou).
    public var excessMl: Int { max(consumedMl - goalMl, 0) }

    public var goalReached: Bool { consumedMl >= goalMl }

    public var status: GoalStatus {
        if consumedMl == 0 && goalMl > 0 { return .empty }
        if consumedMl > goalMl { return .exceeded }
        if consumedMl == goalMl { return .reached }
        return .inProgress
    }
}
