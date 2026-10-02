import Foundation

/// Sexo informado no onboarding. Usado pelo avatar e disponível para
/// fórmulas de meta que queiram considerá-lo.
public enum Gender: String, Codable, CaseIterable, Identifiable, Sendable {
    case male
    case female

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .male: return "Masculino"
        case .female: return "Feminino"
        }
    }
}
