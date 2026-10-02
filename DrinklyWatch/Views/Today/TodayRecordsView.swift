import SwiftUI
import DrinklyCore

/// Registros de hoje, com edição (toque) e exclusão (deslizar).
struct TodayRecordsView: View {
    @EnvironmentObject private var model: HydrationViewModel

    var body: some View {
        List {
            Section {
                HStack {
                    Text(VolumeFormatter.progress(consumedMl: model.today.consumedMl, goalMl: model.today.goalMl))
                    Spacer()
                    Text("\(model.today.percentage)%")
                        .foregroundColor(Theme.color(for: model.today.status))
                }
                .font(Theme.rounded(.footnote))
                .accessibilityElement(children: .combine)
            }

            if model.todayRecords.isEmpty {
                Text("Nenhum registro hoje.")
                    .foregroundColor(Theme.secondaryText)
            } else {
                Section {
                    ForEach(model.todayRecords) { record in
                        NavigationLink(destination: EditRecordView(record: record)) {
                            RecordRow(record: record)
                        }
                    }
                    .onDelete { offsets in
                        offsets.map { model.todayRecords[$0] }.forEach(model.delete)
                    }
                } footer: {
                    Text("Toque para editar · deslize para excluir")
                }
            }
        }
        .navigationTitle("Hoje")
    }
}
