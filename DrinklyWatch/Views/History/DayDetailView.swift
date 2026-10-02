import SwiftUI
import DrinklyCore

/// Um dia: consumo, meta, percentual, quantidade de registros e a lista de
/// registros (editáveis).
struct DayDetailView: View {
    @EnvironmentObject private var model: HydrationViewModel
    @StateObject private var history: HistoryViewModel

    init(service: HydrationService, day: DayKey) {
        _history = StateObject(wrappedValue: HistoryViewModel(service: service, period: .day(day)))
    }

    var body: some View {
        List {
            PeriodNavigator(title: history.title,
                            canGoForward: history.canGoForward,
                            back: history.goBack,
                            forward: history.goForward)
            if let summary = history.summaries.first {
                VStack(alignment: .leading, spacing: 4) {
                    Text(VolumeFormatter.progress(consumedMl: summary.consumedMl, goalMl: summary.goalMl))
                        .font(Theme.rounded(.headline))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    ProgressBar(progress: summary.progress)
                    HStack {
                        Text("\(summary.percentage)%")
                            .foregroundColor(Theme.color(for: summary.status))
                        Spacer()
                        Text("\(summary.recordCount) registro\(summary.recordCount == 1 ? "" : "s")")
                            .foregroundColor(Theme.secondaryText)
                    }
                    .font(Theme.rounded(.footnote))
                }
                .accessibilityElement(children: .combine)
            }
            if history.records.isEmpty {
                Text("Nenhum registro neste dia.")
                    .foregroundColor(Theme.secondaryText)
            } else {
                ForEach(history.records) { record in
                    NavigationLink(destination: EditRecordView(record: record)) {
                        RecordRow(record: record)
                    }
                }
                .onDelete { offsets in
                    offsets.map { history.records[$0] }.forEach(model.delete)
                }
            }
        }
        .navigationTitle(history.title)
        .onReceive(model.$dataVersion) { _ in history.load() }
    }
}
