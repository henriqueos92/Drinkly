import Foundation
import DrinklyCore

/// Estado do onboarding (primeiro acesso).
final class OnboardingViewModel: ObservableObject {
    enum Step: Int, CaseIterable {
        case gender, height, weight, age, goal

        var title: String {
            switch self {
            case .gender: return "Sexo"
            case .height: return "Altura"
            case .weight: return "Peso"
            case .age: return "Idade"
            case .goal: return "Meta diária"
            }
        }
    }

    @Published var step: Step = .gender
    @Published var gender: Gender = .male
    @Published var heightCm = 170
    @Published var weightKg = 70
    @Published var ageYears = 30
    @Published var isAdjustingGoal = false
    @Published var manualGoalMl = 2000

    var metrics: BodyMetrics {
        BodyMetrics(gender: gender, heightCm: heightCm, weightKg: Double(weightKg), ageYears: ageYears)
    }

    func next() {
        if let next = Step(rawValue: step.rawValue + 1) { step = next }
    }

    func back() {
        if let previous = Step(rawValue: step.rawValue - 1) { step = previous }
    }

    /// Meta automática, a menos que o usuário tenha ajustado manualmente.
    func makeProfile() -> UserProfile {
        UserProfile(gender: gender,
                    heightCm: heightCm,
                    weightKg: Double(weightKg),
                    ageYears: ageYears,
                    goalMode: isAdjustingGoal ? .manual : .automatic,
                    manualGoalMl: manualGoalMl)
    }
}
