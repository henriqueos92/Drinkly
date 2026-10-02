import SwiftUI

/// Texto numérico que "conta" até o novo valor durante a animação
/// (1.000 → 1.500). Usa `Animatable`, compatível com watchOS 8, e só é
/// recalculado enquanto a animação roda — sem timers.
struct AnimatedNumberText: View, Animatable {
    var value: Double
    var format: (Int) -> String

    init(_ value: Int, format: @escaping (Int) -> String) {
        self.value = Double(value)
        self.format = format
    }

    var animatableData: Double {
        get { value }
        set { value = newValue }
    }

    var body: some View {
        Text(format(Int(value.rounded())))
    }
}
