import Foundation

/// Uma regra de cálculo da meta diária.
///
/// AVISO: as fórmulas são estimativas genéricas para fins de bem-estar e não
/// constituem recomendação médica. Novas regras podem ser criadas
/// implementando este protocolo, sem tocar nas telas.
public protocol HydrationGoalFormula: Sendable {
    /// Identificador estável (útil para telemetria/migrações futuras).
    var identifier: String { get }
    /// Meta recomendada em ml, sem arredondamentos.
    func rawGoalMl(for metrics: BodyMetrics) -> Double
}

/// Regra inicial: `meta = peso × fator_ml_por_kg`.
public struct WeightBasedGoalFormula: HydrationGoalFormula {
    public var mlPerKg: Double

    public init(mlPerKg: Double = 35) {
        self.mlPerKg = mlPerKg
    }

    public var identifier: String { "weight-based-\(Int(mlPerKg))" }

    public func rawGoalMl(for metrics: BodyMetrics) -> Double {
        metrics.weightKg * mlPerKg
    }
}

/// Ponto único de cálculo da meta automática. As telas só conhecem este tipo;
/// trocar a fórmula, o arredondamento ou os limites é feito aqui (ou na
/// configuração `HydrationGoalCalculator.default`).
public struct HydrationGoalCalculator: Sendable {
    public var formula: any HydrationGoalFormula
    /// Arredondamento para o múltiplo mais próximo (ml).
    public var roundingStepMl: Int
    /// Limites de segurança para entradas extremas ou digitadas errado.
    public var allowedRangeMl: ClosedRange<Int>

    public init(formula: any HydrationGoalFormula = WeightBasedGoalFormula(),
                roundingStepMl: Int = 50,
                allowedRangeMl: ClosedRange<Int> = 1000...6000) {
        self.formula = formula
        self.roundingStepMl = max(roundingStepMl, 1)
        self.allowedRangeMl = allowedRangeMl
    }

    /// Configuração usada pelo app. Altere aqui para mudar a regra.
    public static let `default` = HydrationGoalCalculator()

    /// Meta recomendada (ml), arredondada e limitada.
    public func recommendedGoalMl(for metrics: BodyMetrics) -> Int {
        let raw = formula.rawGoalMl(for: metrics)
        guard raw.isFinite, raw > 0 else { return allowedRangeMl.lowerBound }
        let step = Double(roundingStepMl)
        let rounded = Int((raw / step).rounded() * step)
        return min(max(rounded, allowedRangeMl.lowerBound), allowedRangeMl.upperBound)
    }

    /// Meta efetiva do perfil, respeitando o modo manual.
    public func effectiveGoalMl(for profile: UserProfile) -> Int {
        switch profile.goalMode {
        case .automatic:
            return recommendedGoalMl(for: profile.bodyMetrics)
        case .manual:
            return min(max(profile.manualGoalMl, Self.manualGoalRange.lowerBound), Self.manualGoalRange.upperBound)
        }
    }

    /// Faixa aceita para metas definidas manualmente.
    public static let manualGoalRange = 500...8000
}
