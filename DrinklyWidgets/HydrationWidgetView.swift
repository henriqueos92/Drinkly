import WidgetKit
import SwiftUI
import DrinklyCore

struct HydrationWidgetView: View {
    let entry: HydrationEntry
    @Environment(\.widgetFamily) private var family

    private var progress: HydrationProgress { entry.snapshot.progress }
    private static let water = Color(red: 0.22, green: 0.66, blue: 1.0)

    var body: some View {
        content
            .widgetURL(DeepLink.quickAdd.url)
            .widgetBackground()
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Hidratação: \(VolumeFormatter.spoken(ml: entry.snapshot.consumedMl)) de \(VolumeFormatter.spoken(ml: entry.snapshot.goalMl)), \(progress.percentage) por cento")
    }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .accessoryCircular:
            circular
        case .accessoryCorner:
            corner
        case .accessoryRectangular:
            rectangular
        case .accessoryInline:
            inline
        default:
            circular
        }
    }

    /// Gota preenchida + percentual.
    private var circular: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 1) {
                DropProgressView(fraction: progress.fraction, fillColor: Self.water)
                    .frame(height: 20)
                    .widgetAccentable()
                Text("\(progress.percentage)%")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
            }
            .padding(4)
        }
    }

    /// Ícone de gota com medidor curvo no canto do mostrador.
    private var corner: some View {
        Image(systemName: "drop.fill")
            .font(.system(size: 20, weight: .semibold))
            .foregroundColor(Self.water)
            .widgetAccentable()
            .widgetLabel {
                Gauge(value: progress.clampedFraction) {
                    Text("Água")
                } currentValueLabel: {
                    Text("\(progress.percentage)%")
                } minimumValueLabel: {
                    Text("")
                } maximumValueLabel: {
                    Text("\(progress.percentage)%")
                }
                .tint(Self.water)
            }
    }

    /// 💧 1.250 / 2.500 ml · barra · faltam X (também usado no Smart Stack).
    private var rectangular: some View {
        HStack(spacing: 6) {
            DropProgressView(fraction: progress.fraction, fillColor: Self.water)
                .frame(width: 22)
                .widgetAccentable()
            VStack(alignment: .leading, spacing: 2) {
                Text("Hidratação \(progress.percentage)%")
                    .font(.system(.headline, design: .rounded))
                    .widgetAccentable()
                Text(VolumeFormatter.progress(consumedMl: entry.snapshot.consumedMl, goalMl: entry.snapshot.goalMl))
                    .font(.system(.body, design: .rounded))
                ProgressView(value: progress.clampedFraction)
                    .tint(Self.water)
                Text(remainingText)
                    .font(.system(.footnote, design: .rounded))
                    .foregroundColor(.secondary)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            Spacer(minLength: 0)
        }
    }

    private var inline: some View {
        Text("💧 \(progress.percentage)% · \(VolumeFormatter.number(entry.snapshot.consumedMl))/\(VolumeFormatter.number(entry.snapshot.goalMl)) ml")
    }

    private var remainingText: String {
        switch progress.status {
        case .empty: return "Toque para registrar"
        case .inProgress: return "Faltam \(VolumeFormatter.string(ml: progress.remainingMl))"
        case .reached: return "Meta atingida!"
        case .exceeded: return "Meta ultrapassada"
        }
    }
}

private extension View {
    /// `containerBackground` é obrigatório a partir do watchOS 10
    /// (Smart Stack); em versões anteriores não existe.
    @ViewBuilder
    func widgetBackground() -> some View {
        if #available(watchOS 10.0, *) {
            containerBackground(for: .widget) {
                LinearGradient(colors: [Color(red: 0.05, green: 0.25, blue: 0.55), Color(red: 0.02, green: 0.12, blue: 0.30)],
                               startPoint: .top, endPoint: .bottom)
            }
        } else {
            self
        }
    }
}

#if DEBUG
struct HydrationWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        let entry = HydrationEntry(date: Date(), snapshot: .placeholder)
        Group {
            HydrationWidgetView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .accessoryCircular))
            HydrationWidgetView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
            HydrationWidgetView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .accessoryCorner))
            HydrationWidgetView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .accessoryInline))
        }
    }
}
#endif
