import Foundation

/// Atalho de registro em um toque: tipo de bebida + volume (ex.: Água 500 ml,
/// Água de coco 300 ml). Aparece como botão na tela inicial.
public struct DrinkShortcut: Codable, Hashable, Identifiable, Sendable {
    public var type: BeverageType
    public var volumeMl: Int

    public init(type: BeverageType = .water, volumeMl: Int) {
        self.type = type
        self.volumeMl = volumeMl
    }

    /// Estável e único: não existem dois atalhos com o mesmo tipo e volume.
    public var id: String { "\(type.rawValue)-\(volumeMl)" }

    public static func water(_ volumeMl: Int) -> DrinkShortcut {
        DrinkShortcut(type: .water, volumeMl: volumeMl)
    }
}
