import SwiftUI
import DrinklyCore

/// Avatar que "enche" de água conforme o progresso do dia.
///
/// - 0%: praticamente vazio · 50%: metade · 100%: cheio.
/// - Acima de 100%: continua cheio e ganha contorno e selo de meta
///   ultrapassada, sem quebrar o layout.
/// - A animação dura ~0,5 s e só acontece quando o valor muda.
struct AvatarView: View {
    let gender: Gender
    /// Fração consumida (pode passar de 1).
    let fraction: Double
    let status: GoalStatus

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let outline = Theme.color(for: status)
        ZStack(alignment: .topTrailing) {
            ZStack {
                AvatarOutline(gender: gender,
                              color: outline.opacity(status == .exceeded || status == .reached ? 1 : 0.6),
                              lineWidth: status == .exceeded ? 5 : 3)
                AvatarSilhouette(gender: gender, color: Color(white: 0.16))
                WaterSurfaceShape(level: fraction)
                    .fill(Theme.waterGradient)
                    .mask(AvatarSilhouette(gender: gender))
            }
            .aspectRatio(AvatarSilhouette.aspectRatio, contentMode: .fit)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.5), value: fraction)

            if status == .reached || status == .exceeded {
                Image(systemName: status == .exceeded ? "star.circle.fill" : "checkmark.circle.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(outline)
                    .background(Circle().fill(Color.black).padding(2))
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(reduceMotion ? nil : .easeOut(duration: 0.3), value: status)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Avatar \(gender == .male ? "masculino" : "feminino")")
        .accessibilityValue(spokenLevel)
    }

    private var spokenLevel: String {
        let percent = HydrationProgress(consumedMl: Int(fraction * 1000), goalMl: 1000).percentage
        switch status {
        case .exceeded: return "Cheio de água, meta ultrapassada, \(percent) por cento"
        case .reached: return "Cheio de água, meta atingida"
        default: return "\(percent) por cento cheio de água"
        }
    }
}

#if DEBUG
struct AvatarView_Previews: PreviewProvider {
    static var previews: some View {
        HStack {
            ForEach([0.0, 0.25, 0.5, 0.75, 1.0, 1.2], id: \.self) { value in
                AvatarView(gender: value < 0.6 ? .male : .female,
                           fraction: value,
                           status: value > 1 ? .exceeded : (value == 1 ? .reached : .inProgress))
            }
        }
        .padding()
    }
}
#endif
