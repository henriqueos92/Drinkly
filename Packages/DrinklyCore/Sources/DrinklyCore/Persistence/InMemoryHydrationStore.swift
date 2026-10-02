import Foundation

/// Implementação em memória para testes, previews do SwiftUI e testes de UI.
public final class InMemoryHydrationStore: HydrationStore {
    private var profile: UserProfile?
    private var goalHistory = GoalHistory()
    private var recordsByID: [UUID: DrinkRecord] = [:]

    public init(profile: UserProfile? = nil, records: [DrinkRecord] = [], goalHistory: GoalHistory = GoalHistory()) {
        self.profile = profile
        self.goalHistory = goalHistory
        for record in records { recordsByID[record.id] = record }
    }

    public func loadProfile() throws -> UserProfile? { profile }
    public func saveProfile(_ profile: UserProfile) throws { self.profile = profile }

    public func loadGoalHistory() throws -> GoalHistory { goalHistory }
    public func saveGoalHistory(_ history: GoalHistory) throws { goalHistory = history }

    public func records(in interval: DateInterval) throws -> [DrinkRecord] {
        recordsByID.values
            .filter { $0.timestamp >= interval.start && $0.timestamp < interval.end }
            .sorted { $0.timestamp < $1.timestamp }
    }

    public func record(id: UUID) throws -> DrinkRecord? { recordsByID[id] }

    public func insert(_ record: DrinkRecord) throws { recordsByID[record.id] = record }

    public func update(_ record: DrinkRecord) throws {
        guard recordsByID[record.id] != nil else { throw HydrationStoreError.recordNotFound(record.id) }
        recordsByID[record.id] = record
    }

    public func deleteRecord(id: UUID) throws {
        guard recordsByID.removeValue(forKey: id) != nil else { throw HydrationStoreError.recordNotFound(id) }
    }

    public func deleteAll() throws {
        profile = nil
        goalHistory = GoalHistory()
        recordsByID = [:]
    }
}
