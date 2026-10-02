import Foundation

/// Links internos usados por complicações, widgets e atalhos para abrir o app
/// diretamente em uma tela.
public enum DeepLink: Equatable, Sendable {
    /// Tela de registro rápido (+200 / +300 / +500...).
    case quickAdd
    case dashboard

    public static let scheme = "drinkly"

    public var url: URL {
        switch self {
        case .quickAdd: return URL(string: "\(Self.scheme)://quick-add")!
        case .dashboard: return URL(string: "\(Self.scheme)://dashboard")!
        }
    }

    public init?(url: URL) {
        guard url.scheme?.lowercased() == Self.scheme else { return nil }
        switch url.host?.lowercased() {
        case "quick-add": self = .quickAdd
        case "dashboard", nil: self = .dashboard
        default: return nil
        }
    }
}
