import Foundation
import DrinklyCore
#if canImport(WidgetKit)
import WidgetKit
#endif
#if canImport(ClockKit)
import ClockKit
#endif

/// Atualiza as complicações sempre que os dados mudam.
///
/// - watchOS 9+: WidgetKit (`DrinklyWidgets`).
/// - watchOS 8 (ex.: Apple Watch Series 3): ClockKit (`ComplicationController`).
/// Ambos leem o mesmo `HydrationSnapshot`, sem duplicar regra de negócio.
final class ComplicationService: HydrationObserver {
    static let widgetKind = "HydrationProgress"

    private let isEnabled: Bool

    init(isEnabled: Bool = true) {
        self.isEnabled = isEnabled
    }

    func reloadAll() {
        guard isEnabled else { return }
        if #available(watchOS 9.0, *) {
            #if canImport(WidgetKit)
            WidgetCenter.shared.reloadTimelines(ofKind: Self.widgetKind)
            #endif
        } else {
            #if canImport(ClockKit)
            let server = CLKComplicationServer.sharedInstance()
            server.activeComplications?.forEach { server.reloadTimeline(for: $0) }
            #endif
        }
    }

    func hydrationService(_ service: HydrationService, didApply change: HydrationChange) {
        reloadAll()
    }
}
