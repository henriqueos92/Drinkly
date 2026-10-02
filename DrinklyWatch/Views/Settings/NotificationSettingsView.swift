import SwiftUI
import DrinklyCore

/// Lembretes: ativar, intervalo (30/60/90/120/personalizado), janela de horário.
struct NotificationSettingsView: View {
    @EnvironmentObject private var model: HydrationViewModel
    @State private var settings: ReminderSettings
    @State private var usesCustomInterval: Bool

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "pt_BR")
        f.dateFormat = "HH:mm"
        return f
    }()

    init(profile: UserProfile) {
        _settings = State(initialValue: profile.reminders)
        _usesCustomInterval = State(initialValue: !ReminderSettings.presetIntervals.contains(profile.reminders.intervalMinutes))
    }

    private var intervalSelection: Binding<Int> {
        Binding(get: { usesCustomInterval ? -1 : settings.intervalMinutes },
                set: { value in
                    if value == -1 {
                        usesCustomInterval = true
                    } else {
                        usesCustomInterval = false
                        settings.intervalMinutes = value
                    }
                })
    }

    var body: some View {
        List {
            Toggle("Lembretes", isOn: $settings.isEnabled)
                .accessibilityIdentifier("remindersEnabled")

            if settings.isEnabled {
                Section {
                    Picker("Intervalo", selection: intervalSelection) {
                        ForEach(ReminderSettings.presetIntervals, id: \.self) { minutes in
                            Text("\(minutes) min").tag(minutes)
                        }
                        Text("Personalizado").tag(-1)
                    }
                    if usesCustomInterval {
                        IntervalMinutesPicker(minutes: $settings.intervalMinutes)
                    }
                } header: {
                    Text("Intervalo")
                }

                Section {
                    TimeOfDayPicker(title: "Início", minuteOfDay: $settings.startMinuteOfDay)
                    TimeOfDayPicker(title: "Fim", minuteOfDay: $settings.endMinuteOfDay, allowsEndOfDay: true)
                    if !settings.hasValidWindow {
                        Text("O horário final deve ser depois do inicial.")
                            .font(.footnote)
                            .foregroundColor(.orange)
                    }
                } header: {
                    Text("Período")
                }

                Toggle("Parar ao atingir a meta", isOn: $settings.stopWhenGoalReached)

                Section {
                    Text(nextReminderText)
                        .font(.footnote)
                        .foregroundColor(Theme.secondaryText)
                } footer: {
                    Text("Os lembretes começam após a primeira bebida do dia.")
                }
            }
        }
        .navigationTitle("Notificações")
        .onDisappear(perform: save)
    }

    private var nextReminderText: String {
        if let date = model.nextReminderDate {
            return "Próximo lembrete: \(Self.timeFormatter.string(from: date))"
        }
        return model.todayRecords.isEmpty ? "Aguardando a primeira bebida de hoje." : "Nenhum lembrete pendente hoje."
    }

    private func save() {
        guard var profile = model.profile, profile.reminders != settings, settings.hasValidWindow else { return }
        profile.reminders = settings
        model.saveProfile(profile)
    }
}

/// Seleção livre do intervalo (15–360 min) com a Digital Crown.
private struct IntervalMinutesPicker: View {
    @Binding var minutes: Int

    var body: some View {
        NumberWheelPicker(title: "Minutos", value: $minutes,
                          range: ReminderSettings.allowedIntervalRange.lowerBound...ReminderSettings.allowedIntervalRange.upperBound,
                          step: 5, unit: "min")
    }
}
