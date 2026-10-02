import SwiftUI

/// Botão grande e de alto contraste para ações rápidas.
struct BigButtonStyle: ButtonStyle {
    var background: Color = Theme.buttonBackground
    var foreground: Color = .white

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.rounded(.headline))
            .foregroundColor(foreground)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .frame(maxWidth: .infinity, minHeight: 44)
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
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 2) {
                Text("+\(volumeMl)")
                Text("ml")
                    .font(Theme.rounded(.footnote, weight: .medium))
                    .foregroundColor(Theme.secondaryText)
            }
        }
        .buttonStyle(BigButtonStyle())
        .accessibilityLabel("Adicionar \(volumeMl) mililitros de \(type.spokenName)")
        .accessibilityIdentifier("\(identifierPrefix)-\(volumeMl)")
    }
}

/// Nome falado da bebida para o VoiceOver.
struct BeverageTypeLabel {
    let spokenName: String
    static let water = BeverageTypeLabel(spokenName: "água")
}
