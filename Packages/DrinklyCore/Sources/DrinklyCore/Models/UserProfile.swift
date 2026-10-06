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
    public static let defaultShortcuts = defaultQuickAmounts.map(DrinkShortcut.water)
    /// Limite de atalhos na tela inicial (mantém a coluna curta no relógio).
    public static let maxShortcuts = 8
    public static let allowedVolumeRange = 10...3000

    public let id: UUID
    public var gender: Gender
    public var heightCm: Int
    public var weightKg: Double
    public var ageYears: Int

    public var goalMode: GoalMode
    /// Usado quando `goalMode == .manual`.
    public var manualGoalMl: Int

    /// Atalhos da tela inicial, na ordem exibida.
    public var shortcuts: [DrinkShortcut]
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
                shortcuts: [DrinkShortcut] = UserProfile.defaultShortcuts,
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
        self.shortcuts = UserProfile.sanitizedShortcuts(shortcuts)
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

    /// Volumes dos atalhos de água, na ordem exibida (usados nas ações das
    /// notificações, na Siri e nas complicações).
    public var quickAmounts: [Int] {
        shortcuts.filter { $0.type == .water }.map(\.volumeMl)
    }

    /// Normaliza atalhos: volume dentro da faixa permitida, sem duplicatas
    /// (mantém a primeira ocorrência e a ordem) e no máximo `maxShortcuts`.
    public static func sanitizedShortcuts(_ shortcuts: [DrinkShortcut]) -> [DrinkShortcut] {
        var seen = Set<DrinkShortcut>()
        let valid = shortcuts.filter { allowedVolumeRange.contains($0.volumeMl) && seen.insert($0).inserted }
        return Array(valid.prefix(maxShortcuts))
    }

    /// Adiciona um atalho ao fim da lista, se ainda não existir e houver espaço.
    /// - Returns: `true` se a lista mudou.
    @discardableResult
    public mutating func rememberShortcut(_ shortcut: DrinkShortcut) -> Bool {
        guard UserProfile.allowedVolumeRange.contains(shortcut.volumeMl),
              !shortcuts.contains(shortcut),
              shortcuts.count < UserProfile.maxShortcuts else { return false }
        shortcuts.append(shortcut)
        return true
    }

    private enum CodingKeys: String, CodingKey {
        case id, gender, heightCm, weightKg, ageYears, goalMode, manualGoalMl
        case shortcuts, quickAmounts, reminders, healthKitEnabled, createdAt
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
        if let saved = try c.decodeIfPresent([DrinkShortcut].self, forKey: .shortcuts) {
            shortcuts = UserProfile.sanitizedShortcuts(saved)
        } else {
            // Migração da versão anterior, que guardava só volumes de água.
            let legacy = try c.decodeIfPresent([Int].self, forKey: .quickAmounts) ?? UserProfile.defaultQuickAmounts
            shortcuts = UserProfile.sanitizedShortcuts(legacy.sorted().map(DrinkShortcut.water))
        }
        reminders = try c.decodeIfPresent(ReminderSettings.self, forKey: .reminders) ?? .default
        healthKitEnabled = try c.decodeIfPresent(Bool.self, forKey: .healthKitEnabled) ?? false
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(gender, forKey: .gender)
        try c.encode(heightCm, forKey: .heightCm)
        try c.encode(weightKg, forKey: .weightKg)
        try c.encode(ageYears, forKey: .ageYears)
        try c.encode(goalMode, forKey: .goalMode)
        try c.encode(manualGoalMl, forKey: .manualGoalMl)
        try c.encode(shortcuts, forKey: .shortcuts)
        try c.encode(reminders, forKey: .reminders)
        try c.encode(healthKitEnabled, forKey: .healthKitEnabled)
        try c.encode(createdAt, forKey: .createdAt)
    }
}
