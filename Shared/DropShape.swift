import SwiftUI

/// Gota d'água desenhada em código (sem imagens), usada no app e nas complicações.
struct DropShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let radius = w / 2
        // Centro do arco inferior: a base da gota encosta no fundo do retângulo.
        let center = CGPoint(x: rect.midX, y: rect.maxY - radius)
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addCurve(to: CGPoint(x: rect.maxX, y: center.y),
                      control1: CGPoint(x: rect.midX + w * 0.12, y: rect.minY + h * 0.18),
                      control2: CGPoint(x: rect.maxX, y: center.y - h * 0.22))
        // De 0° a 180° passando por 90° (o ponto mais baixo, com y para baixo).
        path.addArc(center: center, radius: radius,
                    startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false)
        path.addCurve(to: CGPoint(x: rect.midX, y: rect.minY),
                      control1: CGPoint(x: rect.minX, y: center.y - h * 0.22),
                      control2: CGPoint(x: rect.midX - w * 0.12, y: rect.minY + h * 0.18))
        path.closeSubpath()
        return path
    }
}

/// Retângulo que sobe de baixo para cima conforme `level` (0...1). Animável,
/// então a SwiftUI interpola o nível sem timers.
struct FillLevelShape: Shape {
    var level: Double

    var animatableData: Double {
        get { level }
        set { level = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let clamped = min(max(level, 0), 1)
        let height = rect.height * clamped
        return Path(CGRect(x: rect.minX, y: rect.maxY - height, width: rect.width, height: height))
    }
}

/// Gota preenchida proporcionalmente ao progresso.
struct DropProgressView: View {
    var fraction: Double
    var fillColor: Color = .cyan
    var trackOpacity: Double = 0.3

    var body: some View {
        ZStack {
            DropShape().fill(fillColor.opacity(trackOpacity))
            FillLevelShape(level: fraction)
                .fill(fillColor)
                .clipShape(DropShape())
        }
        .aspectRatio(0.78, contentMode: .fit)
        .accessibilityHidden(true)
    }
}
