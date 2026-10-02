import SwiftUI
import DrinklyCore

/// Seletor de volume com a Digital Crown e botões −/+.
/// Funciona em todos os tamanhos (38 mm a 49 mm) e não exige teclado.
struct VolumeCrownPicker: View {
    @Binding var volumeMl: Int
    var range: ClosedRange<Int> = UserProfile.allowedVolumeRange
    var crownStep: Int = 10
    var buttonStep: Int = 50

    @State private var crownValue: Double = 0

    var body: some View {
        VStack(spacing: 6) {
            Text(VolumeFormatter.string(ml: volumeMl))
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
                .accessibilityLabel("Volume")
                .accessibilityValue(VolumeFormatter.spoken(ml: volumeMl))
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
                    .accessibilityLabel("Diminuir \(buttonStep) mililitros")
                Button { step(by: buttonStep) } label: { Image(systemName: "plus") }
                    .buttonStyle(BigButtonStyle())
                    .accessibilityLabel("Aumentar \(buttonStep) mililitros")
            }
        }
        .onAppear { crownValue = Double(volumeMl) }
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
