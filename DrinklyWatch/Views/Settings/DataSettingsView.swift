import SwiftUI
import DrinklyCore

/// Dados: atalho para o histórico, exportação (futura) e apagar tudo.
struct DataSettingsView: View {
    @EnvironmentObject private var model: HydrationViewModel
    @State private var isConfirmingDelete = false

    var body: some View {
        List {
            Button {
                model.selectedTab = .history
            } label: {
                Label("Ver histórico", systemImage: "calendar")
            }

            Label("Exportar (em breve)", systemImage: "square.and.arrow.up")
                .foregroundColor(Theme.secondaryText)
                .accessibilityHint("Disponível em uma versão futura")

            Section {
                Button(role: .destructive) {
                    isConfirmingDelete = true
                } label: {
                    Label("Apagar todos os dados", systemImage: "trash")
                        .foregroundColor(.red)
                }
                .accessibilityIdentifier("deleteAllData")
            } footer: {
                Text("Os dados ficam apenas neste relógio. Nada é enviado para servidores.")
            }
        }
        .navigationTitle("Dados")
        .confirmationDialog("Apagar perfil e todo o histórico? Esta ação não pode ser desfeita.",
                            isPresented: $isConfirmingDelete,
                            titleVisibility: .visible) {
            Button("Apagar tudo", role: .destructive) { model.deleteAllData() }
            Button("Cancelar", role: .cancel) {}
        }
    }
}
