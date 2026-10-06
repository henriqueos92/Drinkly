import SwiftUI
import DrinklyCore

/// Botão grande e de alto contraste para ações rápidas.
struct BigButtonStyle: ButtonStyle {
    var background: Color = Theme.buttonBackground
    var foreground: Color = .white
    var minHeight: CGFloat = 44

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.rounded(.headline))
            .foregroundColor(foreground)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .frame(maxWidth: .infinity, minHeight: minHeight)
            .padding(.horizontal, 4)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(background.opacity(configuration.isPressed ? 0.6 : 1))
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// Botão de atalho ("+500 ml", "🥥 +300 ml Água de coco") usado na tela
/// inicial, no registro rápido e na escolha de volume.
struct QuickAddButton: View {
    let volumeMl: Int
    var beverage: BeverageType = .water
    var identifierPrefix = "quickAdd"
    /// Versão mais baixa, com ícone da bebida, para a coluna da tela inicial.
    var compact = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if compact {
                    Image(systemName: beverage.symbolName)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(beverage.tint)
                }
                VStack(alignment: compact ? .leading : .center, spacing: 0) {
                    HStack(spacing: 2) {
                        Text("+\(volumeMl)")
                        Text("ml")
                            .font(Theme.rounded(.footnote, weight: .medium))
                            .foregroundColor(Theme.secondaryText)
                    }
                    if compact && beverage != .water {
                        Text(beverage.displayName)
                            .font(Theme.rounded(.caption2, weight: .medium))
                            .foregroundColor(Theme.secondaryText)
                    }
                }
            }
        }
        .buttonStyle(BigButtonStyle(minHeight: compact ? 36 : 44))
        .accessibilityLabel("Adicionar \(volumeMl) mililitros de \(beverage.displayName.lowercased())")
        .accessibilityIdentifier(identifier)
    }

    private var identifier: String {
        beverage == .water ? "\(identifierPrefix)-\(volumeMl)" : "\(identifierPrefix)-\(beverage.rawValue)-\(volumeMl)"
    }
}
