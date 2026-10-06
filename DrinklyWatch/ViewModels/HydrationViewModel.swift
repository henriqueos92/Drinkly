import Foundation
import Combine
import DrinklyCore
#if os(watchOS)
import WatchKit
#endif

/// Estado principal do app: progresso de hoje, registros e perfil.
///
/// Toda regra de negócio fica no `HydrationService`; este ViewModel apenas
/// expõe o estado para as telas, traduz erros e dispara feedback háptico.
/// Usado sempre na main thread (SwiftUI); observações de outras origens são
/// redirecionadas para a main queue.
final class HydrationViewModel: ObservableObject {
    @Published private(set) var profile: UserProfile?
    @Published private(set) var today: DailySummary
    @Published private(set) var todayRecords: [DrinkRecord] = []
    /// Incrementado a cada alteração de dados; telas de histórico observam
    /// este valor para recarregar.
    @Published private(set) var dataVersion = 0
    /// Último registro adicionado (permite "Desfazer" sem pedir confirmação).
    @Published private(set) var undoableRecord: DrinkRecord?
    @Published var errorMessage: String?

    @Published var isQuickAddPresented = false
    @Published var selectedTab: MainTab = .dashboard

    let service: HydrationService
    private let notifications: NotificationService?
    private let health: HealthKitService?
    private var undoWorkItem: DispatchWorkItem?

    /// Tempo durante o qual "Desfazer" fica visível.
    static let undoWindow: TimeInterval = 4

    init(service: HydrationService, notifications: NotificationService? = nil, health: HealthKitService? = nil) {
        self.service = service
        self.notifications = notifications
        self.health = health
        self.today = DailySummary(day: service.today, consumedMl: 0, goalMl: service.currentGoalMl(), recordCount: 0)
        service.addObserver(self)
        refresh()
    }

    // MARK: - Leitura

    var progress: HydrationProgress { today.progress }
    /// Atalhos da tela inicial (água e outras bebidas), na ordem exibida.
    var shortcuts: [DrinkShortcut] { profile?.shortcuts ?? UserProfile.defaultShortcuts }

    /// Volumes oferecidos ao escolher uma bebida em "Outras bebidas".
    var volumePresets: [Int] {
        Array(Set([150, 200, 250, 300, 350, 500] + (profile?.quickAmounts ?? []))).sorted()
    }
    var currentGoalMl: Int { service.currentGoalMl() }

    /// Recarrega do disco. Chamado ao abrir o app e na virada do dia.
    func refresh() {
        service.reload()
        profile = service.profile()
        reloadToday()
    }

    private func reloadToday() {
        do {
            today = try service.todaySummary()
            todayRecords = try service.records(on: service.today).sorted { $0.timestamp > $1.timestamp }
        } catch {
            errorMessage = "Não foi possível carregar os dados."
        }
    }

    // MARK: - Registro de bebidas

    /// Adição rápida: registra imediatamente, sem confirmação.
    /// - Parameter rememberShortcut: também guarda a bebida como atalho da
    ///   tela inicial (usado por "Outras bebidas").
    func add(volumeMl: Int, type: BeverageType = .water, rememberShortcut: Bool = false) {
        do {
            let record = try service.addDrink(type: type, volumeMl: volumeMl)
            if rememberShortcut {
                _ = try? service.rememberShortcut(DrinkShortcut(type: type, volumeMl: volumeMl))
            }
            playHaptic(success: true)
            offerUndo(for: record)
        } catch {
            playHaptic(success: false)
            errorMessage = "Volume inválido."
        }
    }

    func undoLastAdd() {
        guard let record = undoableRecord else { return }
        delete(record)
        clearUndo()
    }

    func add(_ shortcut: DrinkShortcut) {
        add(volumeMl: shortcut.volumeMl, type: shortcut.type)
    }

    // MARK: - Atalhos

    func removeShortcut(_ shortcut: DrinkShortcut) {
        do {
            try service.removeShortcut(shortcut)
        } catch {
            errorMessage = "Não foi possível remover o atalho."
        }
    }

    /// Adiciona um atalho manualmente (tela "Editar atalhos").
    /// - Returns: `false` se já existe ou se a lista está cheia.
    @discardableResult
    func addShortcut(_ shortcut: DrinkShortcut) -> Bool {
        do {
            return try service.rememberShortcut(shortcut)
        } catch {
            errorMessage = "Não foi possível salvar o atalho."
            return false
        }
    }

    func update(_ record: DrinkRecord) {
        do {
            try service.updateRecord(record)
        } catch {
            errorMessage = "Não foi possível salvar a alteração."
        }
    }

    func delete(_ record: DrinkRecord) {
        do {
            try service.deleteRecord(record)
            if undoableRecord?.id == record.id { clearUndo() }
        } catch {
            errorMessage = "Não foi possível excluir o registro."
        }
    }

    private func offerUndo(for record: DrinkRecord) {
        undoWorkItem?.cancel()
        undoableRecord = record
        let work = DispatchWorkItem { [weak self] in self?.clearUndo() }
        undoWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.undoWindow, execute: work)
    }

    private func clearUndo() {
        undoWorkItem?.cancel()
        undoWorkItem = nil
        undoableRecord = nil
    }

    // MARK: - Perfil

    func recommendedGoal(for metrics: BodyMetrics) -> Int {
        service.recommendedGoalMl(for: metrics)
    }

    func saveProfile(_ profile: UserProfile) {
        do {
            try service.saveProfile(profile)
        } catch {
            errorMessage = "Não foi possível salvar o perfil."
        }
    }

    func completeOnboarding(with profile: UserProfile) {
        saveProfile(profile)
        notifications?.requestAuthorization()
    }

    func setHealthKitEnabled(_ enabled: Bool) {
        guard var profile = profile else { return }
        guard enabled, let health = health else {
            profile.healthKitEnabled = false
            saveProfile(profile)
            return
        }
        health.requestAuthorization { [weak self] granted in
            guard let self = self, var current = self.profile else { return }
            current.healthKitEnabled = granted
            self.saveProfile(current)
            if !granted {
                self.errorMessage = "Permissão do Apple Health não concedida."
            }
        }
    }

    var isHealthKitAvailable: Bool { health?.isAvailable ?? false }

    func deleteAllData() {
        do {
            try service.deleteAllData()
            selectedTab = .dashboard
        } catch {
            errorMessage = "Não foi possível apagar os dados."
        }
    }

    // MARK: - Lembretes

    var nextReminderDate: Date? { notifications?.nextPlannedReminder() }

    // MARK: - Feedback

    private func playHaptic(success: Bool) {
        #if os(watchOS)
        WKInterfaceDevice.current().play(success ? .success : .failure)
        #endif
    }
}

// MARK: - HydrationObserver

extension HydrationViewModel: HydrationObserver {
    func hydrationService(_ service: HydrationService, didApply change: HydrationChange) {
        // Alterações podem vir da interface, de Siri/Atalhos ou de ações de
        // notificação; o estado publicado é sempre atualizado na main thread.
        if Thread.isMainThread {
            apply(change)
        } else {
            DispatchQueue.main.async { [weak self] in self?.apply(change) }
        }
    }

    private func apply(_ change: HydrationChange) {
        switch change {
        case .profileUpdated(let profile):
            self.profile = profile
        case .allDataDeleted:
            profile = nil
            clearUndo()
        case .recordAdded, .recordUpdated, .recordDeleted:
            break
        }
        reloadToday()
        dataVersion += 1
    }
}
