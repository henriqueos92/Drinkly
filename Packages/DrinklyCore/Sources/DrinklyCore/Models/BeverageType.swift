import Foundation

/// Tipos de bebida pré-configurados.
///
/// O volume é sempre armazenado como ingerido (sem coeficientes de hidratação),
/// conforme solicitado. O `rawValue` é persistido, então não renomeie casos
/// existentes — apenas adicione novos.
public enum BeverageType: String, Codable, CaseIterable, Identifiable, Sendable {
    case water
    case coconutWater
    case juice
    case coffee
    case tea
    case soda
    case other

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .water: return "Água"
        case .coconutWater: return "Água de coco"
        case .juice: return "Suco"
        case .coffee: return "Café"
        case .tea: return "Chá"
        case .soda: return "Refrigerante"
        case .other: return "Outra bebida"
        }
    }

    /// Tolerância a valores desconhecidos (ex.: dados gravados por uma versão
    /// futura do app): caem em `.other` em vez de falhar a decodificação.
    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = BeverageType(rawValue: raw) ?? .other
    }
}
