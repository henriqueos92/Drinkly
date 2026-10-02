import Foundation
import UserNotifications
import DrinklyCore

/// Responsável por toda a lógica de lembretes no sistema.
///
/// As regras (quando lembrar, janela de horário, textos) vivem no
/// `ReminderPlanner` do DrinklyCore, que é testado. Este serviço apenas:
/// 1. pede permissão;
/// 2. reagenda os lembretes do dia sempre que os dados mudam;
/// 3. trata ações rápidas das notificações ("+300 ml").
///
/// Não há timers: os lembretes são entregues pelo próprio watchOS mesmo com o
/// app fechado. Como cada nova bebida reagenda a sequência a partir dela,
/// nunca há um lembrete logo depois de beber.
final class NotificationService: NSObject {
    static let categoryIdentifier = "HYDRATION_REMINDER"
    static let requestPrefix = "drinkly.reminder."
    private static let addActionPrefix = "drinkly.add."

    private let service: HydrationService
    private let planner: ReminderPlanner
    private let isEnabled: Bool
    private var center: UNUserNotificationCenter { .current() }

    init(service: HydrationService, planner: ReminderPlanner = ReminderPlanner(), isEnabled: Bool = true) {
        self.service = service
        self.planner = planner
        self.isEnabled = isEnabled
        super.init()
    }

    /// Deve ser chamado na inicialização do app, antes de qualquer notificação
    /// ser entregue, para tratar ações tocadas com o app fechado.
    func activate() {
        guard isEnabled else { return }
        center.delegate = self
        registerCategories()
    }

    func requestAuthorization(completion: ((Bool) -> Void)? = nil) {
        guard isEnabled else { completion?(false); return }
        center.requestAuthorization(options: [.alert, .sound]) { [weak self] granted, _ in
            DispatchQueue.main.async {
                if granted { self?.reschedule() }
                completion?(granted)
            }
        }
    }

    /// Recalcula e substitui os lembretes pendentes do app.
    func reschedule() {
        guard isEnabled else { return }
        let reminders = currentPlan()
        registerCategories()
        let center = self.center
        center.getPendingNotificationRequests { pending in
            let ours = pending.map(\.identifier).filter { $0.hasPrefix(Self.requestPrefix) }
            center.removePendingNotificationRequests(withIdentifiers: ours)
            for (index, reminder) in reminders.enumerated() {
                center.add(Self.request(for: reminder, index: index))
            }
        }
    }

    func cancelAll() {
        guard isEnabled else { return }
        let center = self.center
        center.getPendingNotificationRequests { pending in
            center.removePendingNotificationRequests(withIdentifiers: pending.map(\.identifier).filter { $0.hasPrefix(Self.requestPrefix) })
        }
    }

    /// Próximo lembrete previsto pelas regras (para exibir nos Ajustes).
    func nextPlannedReminder() -> Date? {
        currentPlan().first?.fireDate
    }

    private func currentPlan() -> [PlannedReminder] {
        guard let context = try? service.reminderContext() else { return [] }
        return planner.plan(for: context, calendar: service.calendar)
    }

    private static func request(for reminder: PlannedReminder, index: Int) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = reminder.title
        content.body = reminder.body
        content.sound = .default
        content.categoryIdentifier = categoryIdentifier
        content.threadIdentifier = "hydration"

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: reminder.fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        return UNNotificationRequest(identifier: "\(requestPrefix)\(index)", content: content, trigger: trigger)
    }

    /// Ações exibidas na notificação: as duas primeiras quantidades rápidas.
    private func registerCategories() {
        let amounts = Array((service.profile()?.quickAmounts ?? UserProfile.defaultQuickAmounts).prefix(2))
        let actions = amounts.map { amount in
            UNNotificationAction(identifier: "\(Self.addActionPrefix)\(amount)",
                                 title: "+\(VolumeFormatter.string(ml: amount)) de água",
                                 options: [])
        }
        let category = UNNotificationCategory(identifier: Self.categoryIdentifier,
                                              actions: actions,
                                              intentIdentifiers: [],
                                              options: [])
        center.setNotificationCategories([category])
    }
}

// MARK: - HydrationObserver

extension NotificationService: HydrationObserver {
    func hydrationService(_ service: HydrationService, didApply change: HydrationChange) {
        switch change {
        case .allDataDeleted:
            cancelAll()
        case .recordAdded, .recordUpdated, .recordDeleted, .profileUpdated:
            // Primeira bebida do dia ativa a rotina; as seguintes empurram o
            // próximo lembrete; editar/excluir e mudar ajustes recalculam.
            reschedule()
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let action = response.actionIdentifier
        let service = self.service
        DispatchQueue.main.async {
            if action.hasPrefix(Self.addActionPrefix),
               let amount = Int(action.dropFirst(Self.addActionPrefix.count)) {
                _ = try? service.addDrink(type: .water, volumeMl: amount)
            }
            completionHandler()
        }
    }
}
