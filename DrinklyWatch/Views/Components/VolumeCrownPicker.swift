import SwiftUI
import DrinklyCore

/// Seletor numérico com a Digital Crown e botões −/+ (volumes em ml por
/// padrão; também usado para minutos). Funciona em todos os tamanhos
/// (38 mm a 49 mm) e não exige teclado.
struct VolumeCrownPicker: View {
    @Binding var volumeMl: Int
    var range: ClosedRange<Int> = UserProfile.allowedVolumeRange
    var crownStep: Int = 10
    var buttonStep: Int = 50
    var label = "Volume"
    var format: (Int) -> String = { VolumeFormatter.string(ml: $0) }
    var spokenFormat: (Int) -> String = { VolumeFormatter.spoken(ml: $0) }

    @State private var crownValue: Double = 0

    var body: some View {
        VStack(spacing: 6) {
            Text(format(volumeMl))
                .font(Theme.rounded(.title2))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 10).stroke(Theme.water, lineWidth: 2))
                .focusable(true)
                .digitalCrownRotation($crownValue,
                                      from: Double(range.lowerBound),
                                      through: Double(range.upperBound),
                                      by: Double(crownStep),
                                      sensitivity: .medium,
                                      isContinuous: false,
                                      isHapticFeedbackEnabled: true)
                .accessibilityLabel(label)
                .accessibilityValue(spokenFormat(volumeMl))
                .accessibilityAdjustableAction { direction in
                    switch direction {
                    case .increment: step(by: buttonStep)
                    case .decrement: step(by: -buttonStep)
                    @unknown default: break
                    }
                }

            HStack(spacing: 6) {
                Button { step(by: -buttonStep) } label: { Image(systemName: "minus") }
                    .buttonStyle(BigButtonStyle())
                    .accessibilityLabel("Diminuir \(spokenFormat(buttonStep))")
                Button { step(by: buttonStep) } label: { Image(systemName: "plus") }
                    .buttonStyle(BigButtonStyle())
                    .accessibilityLabel("Aumentar \(spokenFormat(buttonStep))")
            }
        }
        .onAppear { crownValue = Double(volumeMl) }
        .onChange(of: volumeMl) { newValue in
            // Mantém a Crown em sincronia quando o valor muda por fora
            // (ex.: botões de intervalo pré-definido).
            if Int(crownValue.rounded()) != newValue { crownValue = Double(newValue) }
        }
        .onChange(of: crownValue) { newValue in
            let snapped = Int((newValue / Double(crownStep)).rounded()) * crownStep
            let clamped = min(max(snapped, range.lowerBound), range.upperBound)
            if clamped != volumeMl { volumeMl = clamped }
        }
    }

    private func step(by delta: Int) {
        let next = min(max(volumeMl + delta, range.lowerBound), range.upperBound)
        volumeMl = next
        crownValue = Double(next)
    }
}
