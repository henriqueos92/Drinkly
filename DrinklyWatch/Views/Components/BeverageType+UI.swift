import SwiftUI
import DrinklyCore

extension BeverageType {
    /// SF Symbols disponíveis desde o watchOS 8 (SF Symbols 3).
    var symbolName: String {
        switch self {
        case .water: return "drop.fill"
        case .coconutWater: return "leaf.fill"
        case .juice: return "takeoutbag.and.cup.and.straw.fill"
        case .coffee: return "mug.fill"
        case .tea: return "cup.and.saucer.fill"
        case .soda: return "sparkles"
        case .other: return "ellipsis.circle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .water: return Theme.water
        case .coconutWater: return .green
        case .juice: return .orange
        case .coffee: return .brown
        case .tea: return .yellow
        case .soda: return .red
        case .other: return .gray
        }
    }
}
