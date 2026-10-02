import SwiftUI
import DrinklyCore

struct ProfileSettingsView: View {
    @EnvironmentObject private var model: HydrationViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var draft: UserProfile
    @State private var weightKg: Int

    init(profile: UserProfile) {
        _draft = State(initialValue: profile)
        _weightKg = State(initialValue: Int(profile.weightKg.rounded()))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text("Sexo").font(.footnote).foregroundColor(Theme.secondaryText)
                Picker("Sexo", selection: $draft.gender) {
                    ForEach(Gender.allCases) { Text($0.displayName).tag($0) }
                }
                .pickerStyle(.wheel)
                .frame(height: 50)

                Text("Altura").font(.footnote).foregroundColor(Theme.secondaryText)
                NumberWheelPicker(title: "Altura", value: $draft.heightCm, range: 100...230, unit: "cm")

                Text("Peso").font(.footnote).foregroundColor(Theme.secondaryText)
                NumberWheelPicker(title: "Peso", value: $weightKg, range: 30...250, unit: "kg")

                Text("Idade").font(.footnote).foregroundColor(Theme.secondaryText)
                NumberWheelPicker(title: "Idade", value: $draft.ageYears, range: 10...100, unit: "anos")

                Button {
                    draft.weightKg = Double(weightKg)
                    model.saveProfile(draft)
                    dismiss()
                } label: {
                    Label("Salvar", systemImage: "checkmark")
                }
                .buttonStyle(BigButtonStyle(background: Theme.waterDeep))
            }
        }
        .navigationTitle("Perfil")
    }
}
