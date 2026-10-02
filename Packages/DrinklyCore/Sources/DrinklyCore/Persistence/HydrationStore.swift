import Foundation

/// Contrato de persistência. As camadas superiores dependem apenas deste
/// protocolo, então é possível trocar a implementação (SwiftData, Core Data,
/// CloudKit, sincronização com iPhone) sem alterar regras de negócio ou telas.
public protocol HydrationStore: AnyObject {
    func loadProfile() throws -> UserProfile?
    func saveProfile(_ profile: UserProfile) throws

    func loadGoalHistory() throws -> GoalHistory
    func saveGoalHistory(_ history: GoalHistory) throws

    /// Registros com `timestamp` dentro do intervalo, em ordem cronológica.
    func records(in interval: DateInterval) throws -> [DrinkRecord]
    func record(id: UUID) throws -> DrinkRecord?
    func insert(_ record: DrinkRecord) throws
    func update(_ record: DrinkRecord) throws
    func deleteRecord(id: UUID) throws

    /// Apaga perfil, metas e todo o histórico.
    func deleteAll() throws
}

public enum HydrationStoreError: Error, Equatable {
    case recordNotFound(UUID)
}
