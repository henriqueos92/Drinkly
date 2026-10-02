import SwiftUI
import DrinklyCore

/// Barra horizontal simples (sem dependência do Swift Charts, que exige
/// watchOS 9): leve e legível em telas pequenas.
struct ProgressBar: View {
    let progress: HydrationProgress
    var height: CGFloat = 8

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.15))
                Capsule()
                    .fill(Theme.color(for: progress.status))
                    .frame(width: max(proxy.size.width * CGFloat(progress.clampedFraction), progress.consumedMl > 0 ? height : 0))
            }
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }
}

/// Linha "Seg ████████ 90%" usada em semana, mês e últimos dias.
struct DayBarRow: View {
    let label: String
    let summary: DailySummary
    var showsVolume = false

    var body: some View {
        HStack(spacing: 6) {
            Text(label)
                .font(Theme.rounded(.footnote, weight: .medium))
                .frame(minWidth: 34, alignment: .leading)
                .lineLimit(1)
            ProgressBar(progress: summary.progress)
            Text(showsVolume ? VolumeFormatter.number(summary.consumedMl) : "\(summary.percentage)%")
                .font(Theme.rounded(.footnote))
                .foregroundColor(summary.goalReached ? Theme.color(for: summary.status) : .white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(minWidth: 36, alignment: .trailing)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(VolumeFormatter.spoken(ml: summary.consumedMl)), \(summary.percentage) por cento da meta")
    }
}

/// Par rótulo/valor para estatísticas.
struct StatRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title).foregroundColor(Theme.secondaryText)
            Spacer(minLength: 4)
            Text(value).font(Theme.rounded(.footnote))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .font(.footnote)
        .accessibilityElement(children: .combine)
    }
}

/// Botões ‹ › para navegar entre períodos.
struct PeriodNavigator: View {
    let title: String
    let canGoForward: Bool
    let back: () -> Void
    let forward: () -> Void

    var body: some View {
        HStack {
            Button(action: back) { Image(systemName: "chevron.left") }
                .buttonStyle(.plain)
                .frame(width: 30, height: 30)
                .accessibilityLabel("Período anterior")
            Spacer(minLength: 0)
            Text(title)
                .font(Theme.rounded(.footnote))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Spacer(minLength: 0)
            Button(action: forward) { Image(systemName: "chevron.right") }
                .buttonStyle(.plain)
                .frame(width: 30, height: 30)
                .opacity(canGoForward ? 1 : 0.3)
                .disabled(!canGoForward)
                .accessibilityLabel("Próximo período")
        }
    }
}
