import Foundation
import DrinklyCore
#if canImport(HealthKit)
import HealthKit
#endif

/// Integração opcional com o Apple Health (consumo de água — `dietaryWater`).
///
/// - Só grava se o usuário ativou a integração nos Ajustes **e** autorizou.
/// - Cada registro usa `HKMetadataKeySyncIdentifier` = id do registro e
///   `HKMetadataKeySyncVersion` = revisão. Editar substitui a amostra (sem
///   duplicar) e excluir remove a amostra correspondente.
/// - Evita duplicação: o Drinkly nunca importa amostras de outros apps para o
///   próprio histórico; ele apenas escreve as suas. Se outro app também
///   escreve água no Health, o Health mostra as duas fontes — e o usuário
///   pode desativar a integração aqui.
/// - Todas as bebidas são gravadas como "água" (volume de líquido ingerido),
///   que é a única categoria de hidratação do HealthKit.
final class HealthKitService: HydrationObserver {
    private let service: HydrationService
    private let isEnabled: Bool

    #if canImport(HealthKit)
    private let store = HKHealthStore()
    private var waterType: HKQuantityType? { HKObjectType.quantityType(forIdentifier: .dietaryWater) }
    #endif

    init(service: HydrationService, isEnabled: Bool = true) {
        self.service = service
        self.isEnabled = isEnabled
    }

    var isAvailable: Bool {
        #if canImport(HealthKit)
        return isEnabled && HKHealthStore.isHealthDataAvailable()
        #else
        return false
        #endif
    }

    /// Pede permissão de escrita de água. Retorna na main thread.
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        #if canImport(HealthKit)
        guard isAvailable, let type = waterType else { completion(false); return }
        store.requestAuthorization(toShare: [type], read: []) { [weak self] success, _ in
            DispatchQueue.main.async {
                completion(success && self?.canWrite == true)
            }
        }
        #else
        completion(false)
        #endif
    }

    private var canWrite: Bool {
        #if canImport(HealthKit)
        guard let type = waterType else { return false }
        return store.authorizationStatus(for: type) == .sharingAuthorized
        #else
        return false
        #endif
    }

    private var shouldWrite: Bool {
        isAvailable && service.profile()?.healthKitEnabled == true && canWrite
    }

    // MARK: - HydrationObserver

    func hydrationService(_ service: HydrationService, didApply change: HydrationChange) {
        guard shouldWrite else { return }
        switch change {
        case .recordAdded(let record), .recordUpdated(_, let record):
            save(record)
        case .recordDeleted(let record):
            delete(record)
        case .profileUpdated, .allDataDeleted:
            // "Apagar dados" remove apenas os dados do Drinkly; amostras já
            // enviadas ao Health são gerenciadas pelo app Saúde.
            break
        }
    }

    private func save(_ record: DrinkRecord) {
        #if canImport(HealthKit)
        guard let type = waterType else { return }
        let quantity = HKQuantity(unit: .literUnit(with: .milli), doubleValue: Double(record.volumeMl))
        let metadata: [String: Any] = [
            HKMetadataKeySyncIdentifier: record.id.uuidString,
            HKMetadataKeySyncVersion: NSNumber(value: record.revision),
            "DrinklyBeverageType": record.type.rawValue
        ]
        let sample = HKQuantitySample(type: type, quantity: quantity,
                                      start: record.timestamp, end: record.timestamp,
                                      metadata: metadata)
        store.save(sample) { _, error in
            if let error = error {
                NSLog("Drinkly: falha ao salvar no Health: \(error.localizedDescription)")
            }
        }
        #endif
    }

    private func delete(_ record: DrinkRecord) {
        #if canImport(HealthKit)
        guard let type = waterType else { return }
        let predicate = HKQuery.predicateForObjects(withMetadataKey: HKMetadataKeySyncIdentifier,
                                                    allowedValues: [record.id.uuidString])
        store.deleteObjects(of: type, predicate: predicate) { _, _, error in
            if let error = error {
                NSLog("Drinkly: falha ao excluir do Health: \(error.localizedDescription)")
            }
        }
        #endif
    }
}
