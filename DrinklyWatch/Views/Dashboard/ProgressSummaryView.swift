import SwiftUI
import DrinklyCore

/// "1.250 / 2.500 ml · 50% · Faltam 1.250 ml", com contagem animada.
struct ProgressSummaryView: View {
    let summary: DailySummary
    var alignment: HorizontalAlignment = .center

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: alignment, spacing: 2) {
            AnimatedNumberText(summary.percentage) { "\($0)%" }
                .font(Theme.rounded(.title))
                .foregroundColor(Theme.color(for: summary.status))
                .accessibilityIdentifier("percentage")

            HStack(alignment: .firstTextBaseline, spacing: 0) {
                AnimatedNumberText(summary.consumedMl) { VolumeFormatter.number($0) }
                Text(" / \(VolumeFormatter.number(summary.goalMl)) ml")
                    .foregroundColor(Theme.secondaryText)
            }
            .font(Theme.rounded(.headline))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(VolumeFormatter.spoken(ml: summary.consumedMl)) de \(VolumeFormatter.spoken(ml: summary.goalMl))")
            .accessibilityIdentifier("consumedOfGoal")

            Text(StatusMessage.text(for: summary))
                .font(Theme.rounded(.footnote, weight: .medium))
                .foregroundColor(summary.goalReached ? Theme.color(for: summary.status) : Theme.secondaryText)
                .multilineTextAlignment(alignment == .center ? .center : .leading)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("statusMessage")
        }
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.5), value: summary.consumedMl)
    }
}
