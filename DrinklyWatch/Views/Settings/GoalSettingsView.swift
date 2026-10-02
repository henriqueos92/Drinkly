import SwiftUI
import DrinklyCore

/// Meta automática (calculada pelo HydrationGoalCalculator) ou manual.
struct GoalSettingsView: View {
    @EnvironmentObject private var model: HydrationViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var draft: UserProfile

    init(profile: UserProfile) {
        _draft = State(initialValue: profile)
    }

    private var isAutomatic: Binding<Bool> {
        Binding(get: { draft.goalMode == .automatic },
                set: { draft.goalMode = $0 ? .automatic : .manual })
    }

    var body: some View {
        let recommended = model.recommendedGoal(for: draft.bodyMetrics)
        ScrollView {
            VStack(spacing: 8) {
                Toggle("Meta automática", isOn: isAutomatic)
                    .accessibilityIdentifier("automaticGoal")

                if draft.goalMode == .automatic {
                    Text(VolumeFormatter.string(ml: recommended))
                        .font(Theme.rounded(.title2))
                        .foregroundColor(Theme.water)
                    Text("Estimativa baseada no seu peso. Não é recomendação médica.")
                        .font(.footnote)
                        .foregroundColor(Theme.secondaryText)
                        .multilineTextAlignment(.center)
                } else {
                    VolumeCrownPicker(volumeMl: $draft.manualGoalMl,
                                      range: HydrationGoalCalculator.manualGoalRange,
                                      crownStep: 50,
                                      buttonStep: 250)
                    Text("Sugestão automática: \(VolumeFormatter.string(ml: recommended))")
                        .font(.footnote)
                        .foregroundColor(Theme.secondaryText)
                }

                Button {
                    model.saveProfile(draft)
                    dismiss()
                } label: {
                    Label("Salvar", systemImage: "checkmark")
                }
                .buttonStyle(BigButtonStyle(background: Theme.waterDeep))
                .accessibilityIdentifier("saveGoal")
            }
        }
        .navigationTitle("Meta diária")
        .onAppear {
            if draft.goalMode == .automatic { draft.manualGoalMl = recommended }
        }
    }
}
