import SwiftUI
import DrinklyCore

/// Avatar que "enche" de água conforme o progresso do dia.
///
/// - 0%: praticamente vazio · 50%: metade · 100%: cheio.
/// - Acima de 100%: continua cheio e ganha contorno e selo de meta
///   ultrapassada, sem quebrar o layout.
/// - O nível sobe em ~0,5 s quando uma bebida é registrada.
/// - A superfície da água balança como num copo e "chacoalha" mais logo após
///   cada registro. O movimento usa `TimelineView` a 24 fps e pausa sozinho
///   quando a tela entra no modo sempre ativo (pulso abaixado), quando o app
///   sai de primeiro plano ou quando "Reduzir movimento" está ativo.
struct AvatarView: View {
    let gender: Gender
    /// Fração consumida (pode passar de 1).
    let fraction: Double
    let status: GoalStatus
    var isAnimated: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced
    @Environment(\.scenePhase) private var scenePhase
    @State private var sloshStart = Date.distantPast

    private var animatesWater: Bool {
        isAnimated && !reduceMotion && !isLuminanceReduced && scenePhase == .active
    }

    var body: some View {
        let outline = Theme.color(for: status)
        ZStack(alignment: .topTrailing) {
            ZStack {
                AvatarOutline(gender: gender,
                              color: outline.opacity(status == .exceeded || status == .reached ? 1 : 0.6),
                              lineWidth: status == .exceeded ? 5 : 3)
                AvatarSilhouette(gender: gender, color: Color(white: 0.16))
                water
                    .mask(AvatarSilhouette(gender: gender))
                AvatarMuscleLinesShape(gender: gender)
                    .stroke(Color.white.opacity(0.18), style: StrokeStyle(lineWidth: 1, lineCap: .round))
            }
            .aspectRatio(AvatarSilhouette.aspectRatio, contentMode: .fit)

            if status == .reached || status == .exceeded {
                Image(systemName: status == .exceeded ? "star.circle.fill" : "checkmark.circle.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(outline)
                    .background(Circle().fill(Color.black).padding(2))
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(reduceMotion ? nil : .easeOut(duration: 0.3), value: status)
        .onChange(of: fraction) { _ in
            sloshStart = Date()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Avatar \(gender == .male ? "masculino" : "feminino")")
        .accessibilityValue(spokenLevel)
    }

    @ViewBuilder
    private var water: some View {
        if animatesWater {
            TimelineView(.animation(minimumInterval: 1.0 / 24.0, paused: false)) { context in
                waterShape(motion: WaterMotion(date: context.date, sloshStart: sloshStart))
            }
        } else {
            waterShape(motion: .still)
        }
    }

    private func waterShape(motion: WaterMotion) -> some View {
        WaterSurfaceShape(level: fraction,
                          phase: motion.phase,
                          tilt: motion.tilt,
                          waveHeight: motion.waveHeight)
            .fill(Theme.waterGradient)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.5), value: fraction)
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

/// Movimento da superfície da água em um instante.
struct WaterMotion {
    let phase: Double
    let tilt: CGFloat
    let waveHeight: CGFloat

    static let still = WaterMotion(phase: 0, tilt: 0, waveHeight: 1.5)

    init(phase: Double, tilt: CGFloat, waveHeight: CGFloat) {
        self.phase = phase
        self.tilt = tilt
        self.waveHeight = waveHeight
    }

    /// Balanço contínuo e suave + um "chacoalhão" que decai em ~2 s depois
    /// de cada bebida registrada.
    init(date: Date, sloshStart: Date) {
        let t = date.timeIntervalSinceReferenceDate
        let elapsed = date.timeIntervalSince(sloshStart)
        let boost = elapsed >= 0 ? exp(-elapsed / 0.8) : 0
        phase = t * 2.4
        tilt = CGFloat(sin(t * 1.7) * (2 + 6 * boost))
        waveHeight = CGFloat(1.5 + 2.5 * boost)
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
