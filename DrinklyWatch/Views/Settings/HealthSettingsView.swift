import SwiftUI
import DrinklyCore

/// Conectar/desconectar o Apple Health.
struct HealthSettingsView: View {
    @EnvironmentObject private var model: HydrationViewModel

    var body: some View {
        List {
            if model.isHealthKitAvailable {
                Toggle("Gravar no Apple Health", isOn: Binding(
                    get: { model.profile?.healthKitEnabled ?? false },
                    set: { model.setHealthKitEnabled($0) }))
                    .accessibilityIdentifier("healthToggle")
                Section {
                    Text("Cada bebida é gravada como \"Água\" no app Saúde. Edições e exclusões são refletidas sem duplicar registros.")
                    Text("O Drinkly não importa água registrada por outros apps, evitando contagem dupla.")
                    Text("Para revogar o acesso por completo: Ajustes › Saúde › Acesso a Dados.")
                }
                .font(.footnote)
                .foregroundColor(Theme.secondaryText)
            } else {
                Text("Apple Health indisponível neste dispositivo.")
                    .foregroundColor(Theme.secondaryText)
            }
        }
        .navigationTitle("Apple Health")
    }
}
