import SwiftUI
import DrinklyCore

/// Paleta e tipografia. Cores com alto contraste sobre o fundo preto do
/// watchOS; fontes semânticas acompanham o Dynamic Type.
enum Theme {
    static let water = Color(red: 0.22, green: 0.66, blue: 1.0)
    static let waterDeep = Color(red: 0.05, green: 0.42, blue: 0.95)
    static let reached = Color(red: 0.30, green: 0.85, blue: 0.55)
    static let exceeded = Color(red: 0.25, green: 0.90, blue: 0.85)
    static let secondaryText = Color.white.opacity(0.7)
    static let buttonBackground = Color(red: 0.11, green: 0.24, blue: 0.40)

    static func color(for status: GoalStatus) -> Color {
        switch status {
        case .empty, .inProgress: return water
        case .reached: return reached
        case .exceeded: return exceeded
        }
    }

    static var waterGradient: LinearGradient {
        LinearGradient(colors: [water, waterDeep], startPoint: .top, endPoint: .bottom)
    }

    /// Fonte arredondada que respeita Dynamic Type.
    static func rounded(_ style: Font.TextStyle, weight: Font.Weight = .semibold) -> Font {
        Font.system(style, design: .rounded).weight(weight)
    }
}

/// Mensagem curta exibida abaixo do progresso.
enum StatusMessage {
    static func text(for summary: DailySummary) -> String {
        switch summary.status {
        case .empty: return "Comece registrando sua primeira bebida."
        case .inProgress: return "Faltam \(VolumeFormatter.string(ml: summary.remainingMl))"
        case .reached: return "Meta atingida! 💧"
        case .exceeded: return "Meta ultrapassada! +\(VolumeFormatter.string(ml: summary.progress.excessMl))"
        }
    }
}
