import Foundation

/// Um registro individual de ingestão. É a única fonte de verdade do consumo:
/// totais diários, semanais e mensais são sempre calculados a partir daqui,
/// evitando inconsistência entre registros e agregados.
public struct DrinkRecord: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    /// Data e horário (local do dispositivo no momento do registro).
    public var timestamp: Date
    public var type: BeverageType
    public var volumeMl: Int
    /// Incrementado a cada edição. Usado como versão de sincronização
    /// (Apple Health hoje; iCloud/iPhone no futuro).
    public var revision: Int

    public init(id: UUID = UUID(), timestamp: Date, type: BeverageType, volumeMl: Int, revision: Int = 1) {
        self.id = id
        self.timestamp = timestamp
        self.type = type
        self.volumeMl = volumeMl
        self.revision = revision
    }

    /// Dia (calendário local) ao qual o registro pertence.
    public func day(calendar: Calendar = .current) -> DayKey {
        DayKey(timestamp, calendar: calendar)
    }

    private enum CodingKeys: String, CodingKey {
        case id, timestamp, type, volumeMl, revision
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        timestamp = try c.decode(Date.self, forKey: .timestamp)
        type = try c.decode(BeverageType.self, forKey: .type)
        volumeMl = try c.decode(Int.self, forKey: .volumeMl)
        revision = try c.decodeIfPresent(Int.self, forKey: .revision) ?? 1
    }
}
