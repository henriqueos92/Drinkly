import SwiftUI
import DrinklyCore

/// Edição de um registro: tipo, volume e exclusão. O progresso do dia é
/// recalculado automaticamente a partir dos registros.
struct EditRecordView: View {
    @EnvironmentObject private var model: HydrationViewModel
    @Environment(\.dismiss) private var dismiss

    let record: DrinkRecord
    @State private var type: BeverageType
    @State private var volumeMl: Int
    @State private var isConfirmingDelete = false

    init(record: DrinkRecord) {
        self.record = record
        _type = State(initialValue: record.type)
        _volumeMl = State(initialValue: record.volumeMl)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                Picker("Bebida", selection: $type) {
                    ForEach(BeverageType.allCases) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 60)
                .accessibilityIdentifier("editType")

                VolumeCrownPicker(volumeMl: $volumeMl)

                Button {
                    var updated = record
                    updated.type = type
                    updated.volumeMl = volumeMl
                    model.update(updated)
                    dismiss()
                } label: {
                    Label("Salvar", systemImage: "checkmark")
                }
                .buttonStyle(BigButtonStyle(background: Theme.waterDeep))
                .disabled(type == record.type && volumeMl == record.volumeMl)
                .accessibilityIdentifier("saveRecord")

                Button(role: .destructive) {
                    isConfirmingDelete = true
                } label: {
                    Label("Excluir", systemImage: "trash")
                }
                .buttonStyle(BigButtonStyle(background: Color.red.opacity(0.25), foreground: .red))
                .accessibilityIdentifier("deleteRecord")
            }
        }
        .navigationTitle("Editar")
        .confirmationDialog("Excluir este registro?", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
            Button("Excluir", role: .destructive) {
                model.delete(record)
                dismiss()
            }
            Button("Cancelar", role: .cancel) {}
        }
    }
}
