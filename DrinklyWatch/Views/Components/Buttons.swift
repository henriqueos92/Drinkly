import SwiftUI

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

/// Botão "+500 ml" usado no início, no registro rápido e nos intents.
struct QuickAddButton: View {
    let volumeMl: Int
    var type: BeverageTypeLabel = .water
    var identifierPrefix = "quickAdd"
    /// Versão mais baixa, com ícone de gota, para a coluna da tela inicial.
    var compact = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 2) {
                if compact {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Theme.water)
                        .padding(.trailing, 2)
                }
                Text("+\(volumeMl)")
                Text("ml")
                    .font(Theme.rounded(.footnote, weight: .medium))
                    .foregroundColor(Theme.secondaryText)
            }
        }
        .buttonStyle(BigButtonStyle(minHeight: compact ? 36 : 44))
        .accessibilityLabel("Adicionar \(volumeMl) mililitros de \(type.spokenName)")
        .accessibilityIdentifier("\(identifierPrefix)-\(volumeMl)")
    }
}

/// Nome falado da bebida para o VoiceOver.
struct BeverageTypeLabel {
    let spokenName: String
    static let water = BeverageTypeLabel(spokenName: "água")
}
