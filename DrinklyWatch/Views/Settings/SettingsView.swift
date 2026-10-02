import SwiftUI
import DrinklyCore

/// Ajustes: perfil, meta, bebidas rápidas, notificações, Apple Health e dados.
struct SettingsView: View {
    @EnvironmentObject private var model: HydrationViewModel

    var body: some View {
        List {
            if let profile = model.profile {
                NavigationLink(destination: ProfileSettingsView(profile: profile)) {
                    Label("Perfil", systemImage: "person.fill")
                }
                NavigationLink(destination: GoalSettingsView(profile: profile)) {
                    SettingsRow(title: "Meta", value: VolumeFormatter.string(ml: model.currentGoalMl), symbol: "target")
                }
                NavigationLink(destination: QuickAmountsSettingsView(profile: profile)) {
                    SettingsRow(title: "Bebidas rápidas", value: profile.quickAmounts.map(String.init).joined(separator: " · "), symbol: "bolt.fill")
                }
                NavigationLink(destination: NotificationSettingsView(profile: profile)) {
                    SettingsRow(title: "Notificações",
                                value: profile.reminders.isEnabled ? "A cada \(profile.reminders.clampedIntervalMinutes) min" : "Desativadas",
                                symbol: "bell.fill")
                }
                NavigationLink(destination: HealthSettingsView()) {
                    SettingsRow(title: "Apple Health", value: profile.healthKitEnabled ? "Conectado" : "Desconectado", symbol: "heart.fill")
                }
                NavigationLink(destination: DataSettingsView()) {
                    Label("Dados", systemImage: "externaldrive.fill")
                }
            }
            Section {
                Text("As metas são estimativas para bem-estar e não substituem orientação médica.")
                    .font(.footnote)
                    .foregroundColor(Theme.secondaryText)
            }
        }
        .navigationTitle("Ajustes")
    }
}

struct SettingsRow: View {
    let title: String
    let value: String
    let symbol: String

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                Text(value)
                    .font(.footnote)
                    .foregroundColor(Theme.secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        } icon: {
            Image(systemName: symbol)
        }
    }
}
