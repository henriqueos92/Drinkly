import SwiftUI
import DrinklyCore

/// Lembretes: ativar, intervalo (atalhos 30/60/90/120 ou qualquer valor de
/// 15 a 360 min pela Digital Crown) e janela de horário.
struct NotificationSettingsView: View {
    @EnvironmentObject private var model: HydrationViewModel
    @State private var settings: ReminderSettings

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "pt_BR")
        f.dateFormat = "HH:mm"
        return f
    }()

    init(profile: UserProfile) {
        _settings = State(initialValue: profile.reminders)
    }

    var body: some View {
        List {
            Toggle("Lembretes", isOn: $settings.isEnabled)
                .accessibilityIdentifier("remindersEnabled")

            if settings.isEnabled {
                Section {
                    // Qualquer valor de 15 a 360 min, de 5 em 5, pela Crown ou −/+.
                    VolumeCrownPicker(volumeMl: $settings.intervalMinutes,
                                      range: ReminderSettings.allowedIntervalRange,
                                      crownStep: 5,
                                      buttonStep: 5,
                                      label: "Intervalo dos lembretes",
                                      format: { "\($0) min" },
                                      spokenFormat: { "\($0) minutos" })
                        .accessibilityIdentifier("reminderInterval")
                } header: {
                    Text("Lembrar a cada")
                }

                Section {
                    ForEach(ReminderSettings.presetIntervals, id: \.self) { minutes in
                        Button {
                            settings.intervalMinutes = minutes
                        } label: {
                            HStack {
                                Text(minutes == 30 ? "30 min (meia hora)" : "\(minutes) min")
                                Spacer()
                                if settings.intervalMinutes == minutes {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(Theme.water)
                                }
                            }
                        }
                        .accessibilityAddTraits(settings.intervalMinutes == minutes ? .isSelected : [])
                        .accessibilityIdentifier("interval-\(minutes)")
                    }
                } header: {
                    Text("Atalhos")
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
