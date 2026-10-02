import ClockKit
import UIKit
import DrinklyCore

/// Complicações via ClockKit para watchOS 8 (Apple Watch Series 3 e demais
/// relógios que ainda não atualizaram para o watchOS 9).
///
/// No watchOS 9+ as complicações são fornecidas pela extensão WidgetKit
/// (`DrinklyWidgets`); por isso aqui não é oferecido nenhum descritor nessas
/// versões, evitando opções duplicadas no editor de mostradores.
/// Os dados vêm do mesmo `HydrationSnapshot` usado pelo WidgetKit.
@objc(ComplicationController)
final class ComplicationController: NSObject, CLKComplicationDataSource {
    private static let identifier = "hydration"

    private static let families: [CLKComplicationFamily] = [
        .graphicCircular, .graphicCorner, .graphicRectangular, .graphicBezel,
        .modularSmall, .modularLarge, .circularSmall,
        .utilitarianSmall, .utilitarianSmallFlat, .utilitarianLarge, .extraLarge
    ]

    // MARK: - Configuração

    func getComplicationDescriptors(handler: @escaping ([CLKComplicationDescriptor]) -> Void) {
        if #available(watchOS 9.0, *) {
            handler([])
            return
        }
        handler([
            CLKComplicationDescriptor(identifier: Self.identifier,
                                      displayName: "Hidratação",
                                      supportedFamilies: Self.families)
        ])
    }

    func getPrivacyBehavior(for complication: CLKComplication,
                            withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.showOnLockScreen)
    }

    // MARK: - Linha do tempo

    func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        handler(HydrationSnapshot.loadTimeline().last?.date)
    }

    func getCurrentTimelineEntry(for complication: CLKComplication,
                                 withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        let snapshot = HydrationSnapshot.loadCurrent()
        handler(Self.template(for: complication.family, snapshot: snapshot)
            .map { CLKComplicationTimelineEntry(date: snapshot.date, complicationTemplate: $0) })
    }

    /// Entrega a entrada "zerada" da meia-noite, para que a complicação vire o
    /// dia sem precisar acordar o app.
    func getTimelineEntries(for complication: CLKComplication, after date: Date, limit: Int,
                            withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        let entries = HydrationSnapshot.loadTimeline()
            .filter { $0.date > date }
            .prefix(limit)
            .compactMap { snapshot in
                Self.template(for: complication.family, snapshot: snapshot)
                    .map { CLKComplicationTimelineEntry(date: snapshot.date, complicationTemplate: $0) }
            }
        handler(entries)
    }

    func getLocalizableSampleTemplate(for complication: CLKComplication,
                                      withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        handler(Self.template(for: complication.family, snapshot: .placeholder))
    }

    // MARK: - Templates

    private static let waterColor = UIColor(red: 0.22, green: 0.66, blue: 1.0, alpha: 1)

    static func template(for family: CLKComplicationFamily, snapshot: HydrationSnapshot) -> CLKComplicationTemplate? {
        let progress = snapshot.progress
        let fraction = Float(progress.clampedFraction)
        let percent = CLKSimpleTextProvider(text: "\(progress.percentage)%")
        let amounts = CLKSimpleTextProvider(
            text: VolumeFormatter.progress(consumedMl: snapshot.consumedMl, goalMl: snapshot.goalMl),
            shortText: "\(VolumeFormatter.number(snapshot.consumedMl)) ml")
        let gauge = CLKSimpleGaugeProvider(style: .fill, gaugeColor: waterColor, fillFraction: fraction)

        switch family {
        case .graphicCircular:
            return CLKComplicationTemplateGraphicCircularClosedGaugeText(gaugeProvider: gauge, centerTextProvider: percent)
        case .graphicCorner:
            return CLKComplicationTemplateGraphicCornerGaugeText(gaugeProvider: gauge, outerTextProvider: percent)
        case .graphicBezel:
            let circular = CLKComplicationTemplateGraphicCircularClosedGaugeText(gaugeProvider: gauge, centerTextProvider: percent)
            return CLKComplicationTemplateGraphicBezelCircularText(circularTemplate: circular, textProvider: amounts)
        case .graphicRectangular:
            return CLKComplicationTemplateGraphicRectangularTextGauge(
                headerTextProvider: CLKSimpleTextProvider(text: "💧 Hidratação \(progress.percentage)%"),
                body1TextProvider: amounts,
                gaugeProvider: gauge)
        case .modularSmall:
            return CLKComplicationTemplateModularSmallRingText(textProvider: percent, fillFraction: fraction, ringStyle: .closed)
        case .modularLarge:
            return CLKComplicationTemplateModularLargeStandardBody(
                headerTextProvider: CLKSimpleTextProvider(text: "💧 Hidratação"),
                body1TextProvider: amounts,
                body2TextProvider: CLKSimpleTextProvider(text: "\(progress.percentage)%"))
        case .circularSmall:
            return CLKComplicationTemplateCircularSmallRingText(textProvider: percent, fillFraction: fraction, ringStyle: .closed)
        case .utilitarianSmall:
            return CLKComplicationTemplateUtilitarianSmallRingText(textProvider: percent, fillFraction: fraction, ringStyle: .closed)
        case .utilitarianSmallFlat:
            return CLKComplicationTemplateUtilitarianSmallFlat(textProvider: CLKSimpleTextProvider(text: "💧\(progress.percentage)%"))
        case .utilitarianLarge:
            return CLKComplicationTemplateUtilitarianLargeFlat(
                textProvider: CLKSimpleTextProvider(text: "💧 \(progress.percentage)% · \(amounts.text)"))
        case .extraLarge:
            return CLKComplicationTemplateExtraLargeRingText(textProvider: percent, fillFraction: fraction, ringStyle: .closed)
        default:
            return nil
        }
    }
}
