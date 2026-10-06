import Foundation

/// Alterações aplicadas pelo `HydrationService`, entregues aos observadores
/// (notificações, complicações, Apple Health, sincronização futura).
public enum HydrationChange: Sendable {
    case recordAdded(DrinkRecord)
    case recordUpdated(old: DrinkRecord, new: DrinkRecord)
    case recordDeleted(DrinkRecord)
    case profileUpdated(UserProfile)
    case allDataDeleted
}

/// Efeitos colaterais desacoplados das regras de negócio.
public protocol HydrationObserver: AnyObject {
    func hydrationService(_ service: HydrationService, didApply change: HydrationChange)
}

public enum HydrationServiceError: Error, Equatable {
    case invalidVolume(Int)
    case recordNotFound(UUID)
}

/// Fachada das regras de negócio de hidratação: registra bebidas, calcula
/// progresso/histórico e resolve metas. Não conhece SwiftUI nem frameworks do
/// sistema; efeitos colaterais são feitos pelos `HydrationObserver`s.
public final class HydrationService {
    public let store: HydrationStore
    public var goalCalculator: HydrationGoalCalculator
    public let calendar: Calendar
    public let history: HistoryCalculator
    private let clock: () -> Date
    private var observers: [WeakObserver] = []
    private var cachedProfile: UserProfile??

    /// Meta usada quando ainda não há perfil.
    public static let fallbackGoalMl = 2000

    public init(store: HydrationStore,
                goalCalculator: HydrationGoalCalculator = .default,
                calendar: Calendar = .current,
                clock: @escaping () -> Date = Date.init) {
        self.store = store
        self.goalCalculator = goalCalculator
        self.calendar = calendar
        self.history = HistoryCalculator(calendar: calendar)
        self.clock = clock
    }

    public var now: Date { clock() }
    public var today: DayKey { DayKey(now, calendar: calendar) }

    // MARK: - Observadores

    public func addObserver(_ observer: HydrationObserver) {
        observers.removeAll { $0.value == nil || $0.value === observer }
        observers.append(WeakObserver(value: observer))
    }

    private func notify(_ change: HydrationChange) {
        observers.removeAll { $0.value == nil }
        observers.forEach { $0.value?.hydrationService(self, didApply: change) }
    }

    // MARK: - Perfil e meta

    public func profile() -> UserProfile? {
        if let cached = cachedProfile { return cached }
        let loaded = try? store.loadProfile()
        cachedProfile = .some(loaded)
        return loaded
    }

    /// Descarta caches (ex.: outro processo alterou os arquivos).
    public func reload() {
        cachedProfile = nil
    }

    public var hasCompletedOnboarding: Bool { profile() != nil }

    /// Salva o perfil e registra a meta vigente a partir de hoje.
    /// Dias anteriores continuam avaliados com a meta da época.
    public func saveProfile(_ profile: UserProfile) throws {
        var profile = profile
        profile.shortcuts = UserProfile.sanitizedShortcuts(profile.shortcuts)
        try store.saveProfile(profile)
        var goals = try store.loadGoalHistory()
        goals.setGoal(goalCalculator.effectiveGoalMl(for: profile), from: today)
        try store.saveGoalHistory(goals)
        cachedProfile = .some(profile)
        notify(.profileUpdated(profile))
    }

    /// Meta recomendada para os dados informados (para o onboarding/ajustes).
    public func recommendedGoalMl(for metrics: BodyMetrics) -> Int {
        goalCalculator.recommendedGoalMl(for: metrics)
    }

    /// Meta vigente hoje.
    public func currentGoalMl() -> Int {
        guard let profile = profile() else { return Self.fallbackGoalMl }
        return goalCalculator.effectiveGoalMl(for: profile)
    }

    /// Meta vigente em um dia (usa o histórico de metas).
    public func goal(for day: DayKey) -> Int {
        if day >= today { return currentGoalMl() }
        let goals = (try? store.loadGoalHistory()) ?? GoalHistory()
        return goals.goal(for: day) ?? currentGoalMl()
    }

    // MARK: - Registros

    /// Registra uma bebida. Sem confirmação: é a ação principal do app.
    @discardableResult
    public func addDrink(type: BeverageType = .water, volumeMl: Int, at date: Date? = nil) throws -> DrinkRecord {
        guard UserProfile.allowedVolumeRange.contains(volumeMl) else {
            throw HydrationServiceError.invalidVolume(volumeMl)
        }
        let record = DrinkRecord(timestamp: date ?? now, type: type, volumeMl: volumeMl)
        try store.insert(record)
        notify(.recordAdded(record))
        return record
    }

    /// Guarda a bebida como atalho da tela inicial (ex.: registrada por
    /// "Outras bebidas"). Não faz nada se já existir ou se a lista estiver cheia.
    @discardableResult
    public func rememberShortcut(_ shortcut: DrinkShortcut) throws -> Bool {
        guard var profile = profile(), profile.rememberShortcut(shortcut) else { return false }
        try saveProfile(profile)
        return true
    }

    /// Remove um atalho da tela inicial.
    public func removeShortcut(_ shortcut: DrinkShortcut) throws {
        guard var profile = profile(), profile.shortcuts.contains(shortcut) else { return }
        profile.shortcuts.removeAll { $0 == shortcut }
        try saveProfile(profile)
    }

    /// Edita volume, tipo e/ou horário de um registro existente.
    @discardableResult
    public func updateRecord(_ record: DrinkRecord) throws -> DrinkRecord {
        guard UserProfile.allowedVolumeRange.contains(record.volumeMl) else {
            throw HydrationServiceError.invalidVolume(record.volumeMl)
        }
        guard let old = try store.record(id: record.id) else {
            throw HydrationServiceError.recordNotFound(record.id)
        }
        var updated = record
        updated.revision = old.revision + 1
        try store.update(updated)
        notify(.recordUpdated(old: old, new: updated))
        return updated
    }

    public func deleteRecord(_ record: DrinkRecord) throws {
        do {
            try store.deleteRecord(id: record.id)
        } catch HydrationStoreError.recordNotFound(let id) {
            throw HydrationServiceError.recordNotFound(id)
        }
        notify(.recordDeleted(record))
    }

    public func records(on day: DayKey) throws -> [DrinkRecord] {
        try store.records(in: day.interval(calendar: calendar))
    }

    // MARK: - Progresso e histórico

    public func summary(for day: DayKey) throws -> DailySummary {
        let records = try records(on: day)
        return DailySummary(day: day,
                            consumedMl: records.reduce(0) { $0 + $1.volumeMl },
                            goalMl: goal(for: day),
                            recordCount: records.count)
    }

    public func todaySummary() throws -> DailySummary {
        try summary(for: today)
    }

    /// Resumos dos dias informados com uma única leitura do intervalo.
    public func summaries(for days: [DayKey]) throws -> [DailySummary] {
        guard let first = days.min(), let last = days.max() else { return [] }
        let interval = DateInterval(start: first.startDate(calendar: calendar),
                                    end: last.interval(calendar: calendar).end)
        let records = try store.records(in: interval)
        let goals = (try? store.loadGoalHistory()) ?? GoalHistory()
        let current = currentGoalMl()
        let today = self.today
        return history.summaries(for: days, records: records) { day in
            day >= today ? current : (goals.goal(for: day) ?? current)
        }
    }

    /// Estatísticas considerando apenas dias entre a criação do perfil e hoje.
    public func statistics(for days: [DayKey]) throws -> PeriodStatistics {
        let firstDay = profile().map { DayKey($0.createdAt, calendar: calendar) } ?? DayKey.distantPast
        let eligible = days.filter { $0 >= firstDay && $0 <= today }
        return PeriodStatistics(days: try summaries(for: eligible))
    }

    /// Estado atual para o planejador de lembretes.
    public func reminderContext() throws -> ReminderContext? {
        guard let profile = profile() else { return nil }
        let records = try records(on: today)
        return ReminderContext(now: now,
                               lastDrinkToday: records.map(\.timestamp).max(),
                               consumedTodayMl: records.reduce(0) { $0 + $1.volumeMl },
                               goalMl: currentGoalMl(),
                               settings: profile.reminders)
    }

    /// Apaga perfil e histórico (volta ao onboarding).
    public func deleteAllData() throws {
        try store.deleteAll()
        cachedProfile = nil
        notify(.allDataDeleted)
    }
}

private struct WeakObserver {
    weak var value: HydrationObserver?
}

extension DayKey {
    static let distantPast = DayKey(year: 1, month: 1, day: 1)
}
