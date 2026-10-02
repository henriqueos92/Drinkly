import Foundation
import DrinklyCore

/// Composição das dependências (composition root).
///
/// Um único `HydrationService` é compartilhado entre telas, App Intents
/// (Siri/Atalhos), ações de notificação e complicações ClockKit. Efeitos
/// colaterais (lembretes, complicações, Apple Health) são observadores do
/// serviço, então as regras de negócio não conhecem frameworks do sistema.
final class AppEnvironment {
    static let shared = AppEnvironment(launchMode: LaunchMode.current)

    let service: HydrationService
    let viewModel: HydrationViewModel
    let notifications: NotificationService
    let complications: ComplicationService
    let health: HealthKitService

    init(launchMode: LaunchMode) {
        let store: HydrationStore
        switch launchMode {
        case .normal:
            store = AppGroup.makeStore()
        case .uiTesting(let onboarded):
            store = InMemoryHydrationStore(profile: onboarded ? Self.uiTestProfile : nil)
        }

        service = HydrationService(store: store)
        notifications = NotificationService(service: service, isEnabled: launchMode == .normal)
        complications = ComplicationService(isEnabled: launchMode == .normal)
        health = HealthKitService(service: service, isEnabled: launchMode == .normal)
        viewModel = HydrationViewModel(service: service, notifications: notifications, health: health)

        service.addObserver(notifications)
        service.addObserver(complications)
        service.addObserver(health)

        notifications.activate()
    }

    func appDidBecomeActive() {
        // Reagenda a partir do estado atual (ex.: mudança de fuso horário,
        // dia novo, permissões alteradas nos Ajustes).
        notifications.reschedule()
        complications.reloadAll()
    }

    private static var uiTestProfile: UserProfile {
        UserProfile(gender: .female, heightCm: 165, weightKg: 60, ageYears: 30,
                    goalMode: .manual, manualGoalMl: 2500)
    }
}

/// Modo de execução. Testes de UI rodam com dados em memória e sem efeitos
/// colaterais no sistema.
enum LaunchMode: Equatable {
    case normal
    case uiTesting(onboarded: Bool)

    static var current: LaunchMode {
        let arguments = ProcessInfo.processInfo.arguments
        guard arguments.contains("-ui-testing") else { return .normal }
        return .uiTesting(onboarded: arguments.contains("-onboarded"))
    }
}
