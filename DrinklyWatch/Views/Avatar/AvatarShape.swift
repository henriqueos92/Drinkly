import SwiftUI
import DrinklyCore

/// Peça da silhueta, em coordenadas de um espaço de 100 × 200.
enum AvatarPart {
    case ellipse(CGRect)
    case roundedRect(CGRect, corner: CGFloat)
    case polygon([CGPoint])

    /// Peças de cada avatar. Desenhadas como vetores: escalam sem perda em
    /// qualquer tamanho de tela e não exigem imagens rasterizadas.
    static func parts(for gender: Gender) -> [AvatarPart] {
        switch gender {
        case .male:
            return [
                .ellipse(CGRect(x: 30, y: 4, width: 40, height: 40)),                    // cabeça
                .roundedRect(CGRect(x: 16, y: 50, width: 68, height: 74), corner: 12),  // tronco
                .roundedRect(CGRect(x: 2, y: 54, width: 16, height: 62), corner: 8),    // braço esq.
                .roundedRect(CGRect(x: 82, y: 54, width: 16, height: 62), corner: 8),   // braço dir.
                .roundedRect(CGRect(x: 22, y: 112, width: 26, height: 84), corner: 9),  // perna esq.
                .roundedRect(CGRect(x: 52, y: 112, width: 26, height: 84), corner: 9)   // perna dir.
            ]
        case .female:
            return [
                .ellipse(CGRect(x: 31, y: 6, width: 38, height: 38)),                    // cabeça
                .ellipse(CGRect(x: 38, y: 0, width: 24, height: 14)),                    // coque
                .roundedRect(CGRect(x: 24, y: 50, width: 52, height: 50), corner: 12),  // tronco
                .roundedRect(CGRect(x: 8, y: 54, width: 16, height: 58), corner: 8),    // braço esq.
                .roundedRect(CGRect(x: 76, y: 54, width: 16, height: 58), corner: 8),   // braço dir.
                .polygon([CGPoint(x: 26, y: 92), CGPoint(x: 74, y: 92),
                          CGPoint(x: 90, y: 150), CGPoint(x: 10, y: 150)]),              // saia
                .roundedRect(CGRect(x: 28, y: 140, width: 18, height: 56), corner: 8),  // perna esq.
                .roundedRect(CGRect(x: 54, y: 140, width: 18, height: 56), corner: 8)   // perna dir.
            ]
        }
    }
}

/// Uma peça escalada para o retângulo disponível.
struct AvatarPartShape: Shape {
    let part: AvatarPart

    func path(in rect: CGRect) -> Path {
        let sx = rect.width / 100
        let sy = rect.height / 200
        func scaled(_ r: CGRect) -> CGRect {
            CGRect(x: rect.minX + r.minX * sx, y: rect.minY + r.minY * sy, width: r.width * sx, height: r.height * sy)
        }
        var path = Path()
        switch part {
        case .ellipse(let r):
            path.addEllipse(in: scaled(r))
        case .roundedRect(let r, let corner):
            path.addRoundedRect(in: scaled(r), cornerSize: CGSize(width: corner * sx, height: corner * sy))
        case .polygon(let points):
            path.addLines(points.map { CGPoint(x: rect.minX + $0.x * sx, y: rect.minY + $0.y * sy) })
            path.closeSubpath()
        }
        return path
    }
}

/// Silhueta completa. Cada peça é preenchida separadamente, garantindo a
/// união das formas independentemente do sentido de desenho dos caminhos.
struct AvatarSilhouette: View {
    let gender: Gender
    var color: Color = .white

    static let aspectRatio: CGFloat = 0.5

    var body: some View {
        let parts = AvatarPart.parts(for: gender)
        ZStack {
            ForEach(0..<parts.count, id: \.self) { index in
                AvatarPartShape(part: parts[index]).fill(color)
            }
        }
    }
}

/// Contorno da silhueta. Desenhado por baixo do corpo opaco, de modo que só a
/// borda externa fica visível (sem linhas internas entre as peças).
struct AvatarOutline: View {
    let gender: Gender
    let color: Color
    let lineWidth: CGFloat

    var body: some View {
        let parts = AvatarPart.parts(for: gender)
        ZStack {
            ForEach(0..<parts.count, id: \.self) { index in
                AvatarPartShape(part: parts[index]).stroke(color, lineWidth: lineWidth)
            }
        }
    }
}

/// Superfície da água com uma leve ondulação. O nível é animável, então a
/// água "sobe" suavemente ao registrar uma bebida, sem animação contínua.
struct WaterSurfaceShape: Shape {
    var level: Double
    var waveHeight: CGFloat = 4

    var animatableData: Double {
        get { level }
        set { level = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let clamped = min(max(level, 0), 1)
        guard clamped > 0 else { return Path() }
        // Com o avatar cheio, a onda sai por cima (preenchimento completo).
        let crest = clamped >= 1 ? waveHeight * 2 : 0
        let y = rect.maxY - rect.height * CGFloat(clamped) - crest
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: y))
        let segments = 2
        let width = rect.width / CGFloat(segments)
        for i in 0..<segments {
            let x0 = rect.minX + CGFloat(i) * width
            path.addCurve(to: CGPoint(x: x0 + width, y: y),
                          control1: CGPoint(x: x0 + width * 0.35, y: y - waveHeight),
                          control2: CGPoint(x: x0 + width * 0.65, y: y + waveHeight))
        }
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
