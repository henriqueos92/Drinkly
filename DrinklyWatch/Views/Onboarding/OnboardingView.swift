import SwiftUI
import DrinklyCore

/// Configuração inicial em 5 etapas: sexo → altura → peso → idade → meta.
struct OnboardingView: View {
    @EnvironmentObject private var model: HydrationViewModel
    @StateObject private var onboarding = OnboardingViewModel()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 8) {
                    StepIndicator(current: onboarding.step.rawValue, total: OnboardingViewModel.Step.allCases.count)
                    content
                    navigationButtons
                }
            }
            .navigationTitle(onboarding.step.title)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch onboarding.step {
        case .gender:
            HStack(spacing: 8) {
                ForEach(Gender.allCases) { gender in
                    Button {
                        onboarding.gender = gender
                        onboarding.next()
                    } label: {
                        VStack(spacing: 4) {
                            AvatarView(gender: gender, fraction: 0.6, status: .inProgress)
                                .frame(height: 60)
                            Text(gender.displayName)
                                .font(Theme.rounded(.footnote))
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                        }
                        .padding(6)
                        .frame(maxWidth: .infinity)
                        .background(RoundedRectangle(cornerRadius: 12)
                            .stroke(onboarding.gender == gender ? Theme.water : Color.white.opacity(0.2), lineWidth: 2))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(gender.displayName)
                    .accessibilityIdentifier("gender-\(gender.rawValue)")
                }
            }
        case .height:
            NumberWheelPicker(title: "Altura", value: $onboarding.heightCm, range: 100...230, unit: "cm", height: 80)
        case .weight:
            NumberWheelPicker(title: "Peso", value: $onboarding.weightKg, range: 30...250, unit: "kg", height: 80)
        case .age:
            NumberWheelPicker(title: "Idade", value: $onboarding.ageYears, range: 10...100, unit: "anos", height: 80)
        case .goal:
            goalStep
        }
    }

    private var goalStep: some View {
        let recommended = model.recommendedGoal(for: onboarding.metrics)
        return VStack(spacing: 6) {
            if onboarding.isAdjustingGoal {
                VolumeCrownPicker(volumeMl: $onboarding.manualGoalMl,
                                  range: HydrationGoalCalculator.manualGoalRange,
                                  crownStep: 50,
                                  buttonStep: 250)
            } else {
                Text(VolumeFormatter.string(ml: recommended))
                    .font(Theme.rounded(.title2))
                    .foregroundColor(Theme.water)
                    .accessibilityIdentifier("recommendedGoal")
                Button("Ajustar meta") {
                    onboarding.manualGoalMl = recommended
                    onboarding.isAdjustingGoal = true
                }
                .accessibilityIdentifier("adjustGoal")
            }
            Text("Estimativa para bem-estar. Não é recomendação médica.")
                .font(.footnote)
                .foregroundColor(Theme.secondaryText)
                .multilineTextAlignment(.center)
        }
    }

    private var navigationButtons: some View {
        HStack(spacing: 6) {
            if onboarding.step != .gender {
                Button { onboarding.back() } label: { Image(systemName: "chevron.left") }
                    .buttonStyle(BigButtonStyle(background: Color.white.opacity(0.14)))
                    .frame(width: 50)
                    .accessibilityLabel("Voltar")
            }
            if onboarding.step == .goal {
                Button("Começar") {
                    model.completeOnboarding(with: onboarding.makeProfile())
                }
                .buttonStyle(BigButtonStyle(background: Theme.waterDeep))
                .accessibilityIdentifier("finishOnboarding")
            } else if onboarding.step != .gender {
                Button("Próximo") { onboarding.next() }
                    .buttonStyle(BigButtonStyle(background: Theme.waterDeep))
                    .accessibilityIdentifier("nextStep")
            }
        }
    }
}

private struct StepIndicator: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<total, id: \.self) { index in
                Capsule()
                    .fill(index <= current ? Theme.water : Color.white.opacity(0.2))
                    .frame(height: 3)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Etapa \(current + 1) de \(total)")
    }
}
