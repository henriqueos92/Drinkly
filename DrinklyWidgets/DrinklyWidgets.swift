import WidgetKit
import SwiftUI
import DrinklyCore

/// Extensão de widgets: complicações do mostrador (watchOS 9+) e Smart Stack
/// (watchOS 10+). Os dados vêm do App Group, gravados pelo app.
@main
struct DrinklyWidgetsBundle: WidgetBundle {
    var body: some Widget {
        HydrationProgressWidget()
    }
}

struct HydrationProgressWidget: Widget {
    /// Mesmo valor de `ComplicationService.widgetKind` no app.
    static let kind = "HydrationProgress"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: HydrationTimelineProvider()) { entry in
            HydrationWidgetView(entry: entry)
        }
        .configurationDisplayName("Hidratação")
        .description("Progresso da meta de água. Toque para registrar rapidamente.")
        .supportedFamilies([.accessoryCircular, .accessoryCorner, .accessoryRectangular, .accessoryInline])
    }
}

struct HydrationEntry: TimelineEntry {
    let date: Date
    let snapshot: HydrationSnapshot
}

/// Linha do tempo: o progresso atual e uma entrada zerada à meia-noite, para
/// que a complicação vire o dia sem depender do app. O app pede recarga
/// (`WidgetCenter.reloadTimelines`) a cada novo registro.
struct HydrationTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> HydrationEntry {
        HydrationEntry(date: Date(), snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (HydrationEntry) -> Void) {
        if context.isPreview {
            completion(placeholder(in: context))
        } else {
            let snapshot = HydrationSnapshot.loadCurrent()
            completion(HydrationEntry(date: snapshot.date, snapshot: snapshot))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HydrationEntry>) -> Void) {
        let entries = HydrationSnapshot.loadTimeline().map { HydrationEntry(date: $0.date, snapshot: $0) }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}
