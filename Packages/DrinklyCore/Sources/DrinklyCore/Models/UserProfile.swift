import Foundation

/// Como a meta diária é definida.
public enum GoalMode: String, Codable, CaseIterable, Sendable {
    /// Calculada pelo `HydrationGoalCalculator` a partir do perfil.
    case automatic
    /// Definida manualmente pelo usuário.
    case manual
}

/// Dados corporais usados pelas fórmulas de meta.
public struct BodyMetrics: Hashable, Codable, Sendable {
    public var gender: Gender
    public var heightCm: Int
    public var weightKg: Double
    public var ageYears: Int

    public init(gender: Gender, heightCm: Int, weightKg: Double, ageYears: Int) {
        self.gender = gender
        self.heightCm = heightCm
        self.weightKg = weightKg
        self.ageYears = ageYears
    }
}

/// Perfil e preferências do usuário. Existe um único perfil por dispositivo.
public struct UserProfile: Identifiable, Codable, Hashable, Sendable {
    public static let defaultQuickAmounts = [200, 300, 500, 750]
    public static let maxQuickAmounts = 6
    public static let allowedVolumeRange = 10...3000

    public let id: UUID
    public var gender: Gender
    public var heightCm: Int
    public var weightKg: Double
    public var ageYears: Int

    public var goalMode: GoalMode
    /// Usado quando `goalMode == .manual`.
    public var manualGoalMl: Int

    /// Volumes dos botões de adição rápida (ml), na ordem exibida.
    public var quickAmounts: [Int]
    public var reminders: ReminderSettings
    public var healthKitEnabled: Bool
    /// Data de criação: dias anteriores não entram nas estatísticas.
    public var createdAt: Date

    public init(id: UUID = UUID(),
                gender: Gender,
                heightCm: Int,
                weightKg: Double,
                ageYears: Int,
                goalMode: GoalMode = .automatic,
                manualGoalMl: Int = 2000,
                quickAmounts: [Int] = UserProfile.defaultQuickAmounts,
                reminders: ReminderSettings = .default,
                healthKitEnabled: Bool = false,
                createdAt: Date = Date()) {
        self.id = id
        self.gender = gender
        self.heightCm = heightCm
        self.weightKg = weightKg
        self.ageYears = ageYears
        self.goalMode = goalMode
        self.manualGoalMl = manualGoalMl
        self.quickAmounts = UserProfile.sanitizedQuickAmounts(quickAmounts)
        self.reminders = reminders
        self.healthKitEnabled = healthKitEnabled
        self.createdAt = createdAt
    }

    public var bodyMetrics: BodyMetrics {
        get { BodyMetrics(gender: gender, heightCm: heightCm, weightKg: weightKg, ageYears: ageYears) }
        set {
            gender = newValue.gender
            heightCm = newValue.heightCm
            weightKg = newValue.weightKg
            ageYears = newValue.ageYears
        }
    }

    /// Normaliza volumes rápidos: dentro da faixa permitida, sem duplicatas,
    /// em ordem crescente e no máximo `maxQuickAmounts` itens.
    public static func sanitizedQuickAmounts(_ amounts: [Int]) -> [Int] {
        let valid = amounts.filter { allowedVolumeRange.contains($0) }
        let unique = Array(Set(valid)).sorted()
        let result = Array(unique.prefix(maxQuickAmounts))
        return result.isEmpty ? defaultQuickAmounts : result
    }

    private enum CodingKeys: String, CodingKey {
        case id, gender, heightCm, weightKg, ageYears, goalMode, manualGoalMl
        case quickAmounts, reminders, healthKitEnabled, createdAt
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        gender = try c.decode(Gender.self, forKey: .gender)
        heightCm = try c.decode(Int.self, forKey: .heightCm)
        weightKg = try c.decode(Double.self, forKey: .weightKg)
        ageYears = try c.decode(Int.self, forKey: .ageYears)
        goalMode = try c.decodeIfPresent(GoalMode.self, forKey: .goalMode) ?? .automatic
        manualGoalMl = try c.decodeIfPresent(Int.self, forKey: .manualGoalMl) ?? 2000
        quickAmounts = UserProfile.sanitizedQuickAmounts(try c.decodeIfPresent([Int].self, forKey: .quickAmounts) ?? UserProfile.defaultQuickAmounts)
        reminders = try c.decodeIfPresent(ReminderSettings.self, forKey: .reminders) ?? .default
        healthKitEnabled = try c.decodeIfPresent(Bool.self, forKey: .healthKitEnabled) ?? false
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
    }
}
