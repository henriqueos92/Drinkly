import SwiftUI
import DrinklyCore

// MARK: - Geometria

/// Um trecho de Bézier cúbica (pontos de controle `c1`, `c2` e destino `to`).
struct CurveSegment {
    let c1: CGPoint
    let c2: CGPoint
    let to: CGPoint

    init(_ c1: (CGFloat, CGFloat), _ c2: (CGFloat, CGFloat), _ to: (CGFloat, CGFloat)) {
        self.c1 = CGPoint(x: c1.0, y: c1.1)
        self.c2 = CGPoint(x: c2.0, y: c2.1)
        self.to = CGPoint(x: to.0, y: to.1)
    }
}

/// Silhuetas anatômicas desenhadas em um espaço de 100 × 200.
///
/// Só a metade direita do corpo é descrita (do topo da cabeça até o
/// entrepernas); a esquerda é espelhada, o que garante simetria e um único
/// contorno fechado.
enum AvatarGeometry {
    static let designSize = CGSize(width: 100, height: 200)

    static func start(for gender: Gender) -> CGPoint {
        gender == .male ? CGPoint(x: 50, y: 4) : CGPoint(x: 50, y: 5)
    }

    /// Metade direita do contorno.
    static func rightHalf(for gender: Gender) -> [CurveSegment] {
        switch gender {
        case .male:
            // Corpo atlético: ombros largos, tronco em "V", cintura estreita.
            return [
                CurveSegment((56, 4), (60, 8), (60, 15)),       // crânio
                CurveSegment((60, 22), (58, 26), (56, 29)),     // maxilar
                CurveSegment((54, 32), (54, 34), (54, 37)),     // queixo → pescoço
                CurveSegment((57, 41), (66, 41), (74, 43)),     // trapézio
                CurveSegment((82, 45), (86, 51), (86, 60)),     // deltoide
                CurveSegment((87, 70), (89, 78), (89, 88)),     // braço
                CurveSegment((89, 98), (88, 106), (87, 113)),   // antebraço
                CurveSegment((88, 118), (86, 123), (83, 123)),  // mão
                CurveSegment((80, 123), (79, 118), (80, 112)),
                CurveSegment((80, 102), (80, 96), (79, 88)),    // antebraço (interno)
                CurveSegment((78, 78), (76, 68), (73, 62)),     // braço (interno) → axila
                CurveSegment((71, 74), (67, 84), (64, 96)),     // dorsal em "V" → cintura
                CurveSegment((64, 102), (68, 106), (68, 112)),  // quadril
                CurveSegment((70, 126), (67, 140), (65, 152)),  // coxa → joelho
                CurveSegment((65, 166), (65, 178), (62, 188)),  // panturrilha
                CurveSegment((63, 192), (66, 195), (65, 197)),  // pé
                CurveSegment((62, 199), (56, 199), (54, 197)),
                CurveSegment((54, 182), (53, 166), (54, 152)),  // panturrilha (interna)
                CurveSegment((55, 136), (54, 120), (50, 113))   // coxa (interna) → entrepernas
            ]
        case .female:
            // Corpo atlético: ombros mais estreitos, cintura marcada, quadril.
            return [
                CurveSegment((56, 5), (60, 9), (60, 16)),
                CurveSegment((60, 23), (58, 28), (56, 30)),
                CurveSegment((54, 33), (53, 34), (53, 38)),
                CurveSegment((56, 42), (62, 43), (67, 45)),
                CurveSegment((72, 47), (74, 52), (74, 58)),
                CurveSegment((75, 68), (78, 77), (79, 87)),
                CurveSegment((80, 96), (80, 103), (80, 110)),
                CurveSegment((81, 115), (79, 120), (76, 120)),
                CurveSegment((73, 120), (72, 115), (73, 109)),
                CurveSegment((73, 100), (72, 94), (71, 87)),
                CurveSegment((70, 77), (68, 68), (66, 62)),
                CurveSegment((68, 72), (65, 82), (62, 90)),     // busto → cintura
                CurveSegment((61, 98), (70, 104), (70, 114)),   // quadril
                CurveSegment((70, 128), (67, 141), (63, 153)),
                CurveSegment((62, 167), (62, 178), (60, 188)),
                CurveSegment((61, 192), (63, 195), (62, 197)),
                CurveSegment((60, 199), (55, 199), (53, 197)),
                CurveSegment((53, 182), (52, 167), (53, 153)),
                CurveSegment((54, 138), (53, 124), (50, 118))
            ]
        }
    }

    /// Formas adicionais unidas ao corpo (ex.: coque do cabelo).
    static func extras(for gender: Gender) -> [CGRect] {
        switch gender {
        case .male: return []
        case .female: return [CGRect(x: 40, y: -1, width: 20, height: 13)]
        }
    }
}

private extension CGPoint {
    var mirrored: CGPoint { CGPoint(x: AvatarGeometry.designSize.width - x, y: y) }

    func scaled(to rect: CGRect) -> CGPoint {
        CGPoint(x: rect.minX + x * rect.width / AvatarGeometry.designSize.width,
                y: rect.minY + y * rect.height / AvatarGeometry.designSize.height)
    }
}

// MARK: - Shapes

/// Contorno completo do corpo (metade direita + espelho da esquerda).
struct AvatarBodyShape: Shape {
    let gender: Gender

    func path(in rect: CGRect) -> Path {
        let start = AvatarGeometry.start(for: gender)
        let segments = AvatarGeometry.rightHalf(for: gender)
        var path = Path()
        path.move(to: start.scaled(to: rect))

        // Metade direita, de cima para baixo.
        var starts: [CGPoint] = []
        var current = start
        for segment in segments {
            starts.append(current)
            path.addCurve(to: segment.to.scaled(to: rect),
                          control1: segment.c1.scaled(to: rect),
                          control2: segment.c2.scaled(to: rect))
            current = segment.to
        }

        // Metade esquerda: os mesmos trechos espelhados, percorridos ao contrário.
        for (segment, segmentStart) in zip(segments, starts).reversed() {
            path.addCurve(to: segmentStart.mirrored.scaled(to: rect),
                          control1: segment.c2.mirrored.scaled(to: rect),
                          control2: segment.c1.mirrored.scaled(to: rect))
        }
        path.closeSubpath()
        return path
    }
}

/// Uma forma extra (elipse) no espaço de desenho do avatar.
struct AvatarExtraShape: Shape {
    let frame: CGRect

    func path(in rect: CGRect) -> Path {
        let origin = frame.origin.scaled(to: rect)
        let size = CGSize(width: frame.width * rect.width / AvatarGeometry.designSize.width,
                          height: frame.height * rect.height / AvatarGeometry.designSize.height)
        return Path(ellipseIn: CGRect(origin: origin, size: size))
    }
}

/// Linhas sutis de definição muscular (peitoral e abdômen) do avatar masculino.
struct AvatarMuscleLinesShape: Shape {
    let gender: Gender

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard gender == .male else { return path }
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y).scaled(to: rect) }

        // Peitoral (contorno inferior, dos dois lados).
        for side in [CGFloat(1), CGFloat(-1)] {
            let x: (CGFloat) -> CGFloat = { 50 + side * ($0 - 50) }
            path.move(to: p(x(51), 66))
            path.addCurve(to: p(x(68), 61), control1: p(x(57), 70), control2: p(x(64), 68))
        }
        // Linha central do abdômen e duas divisões.
        path.move(to: p(50, 70))
        path.addLine(to: p(50, 102))
        path.move(to: p(44, 81))
        path.addQuadCurve(to: p(56, 81), control: p(50, 83))
        path.move(to: p(45, 91))
        path.addQuadCurve(to: p(55, 91), control: p(50, 93))
        return path
    }
}

/// Silhueta completa (corpo + extras). As peças são preenchidas
/// separadamente, garantindo a união independentemente do sentido do traço.
struct AvatarSilhouette: View {
    let gender: Gender
    var color: Color = .white

    static let aspectRatio: CGFloat = AvatarGeometry.designSize.width / AvatarGeometry.designSize.height

    var body: some View {
        let extras = AvatarGeometry.extras(for: gender)
        ZStack {
            AvatarBodyShape(gender: gender).fill(color)
            ForEach(0..<extras.count, id: \.self) { index in
                AvatarExtraShape(frame: extras[index]).fill(color)
            }
        }
    }
}

/// Contorno da silhueta. Desenhado por baixo do corpo opaco, de modo que só a
/// borda externa fica visível.
struct AvatarOutline: View {
    let gender: Gender
    let color: Color
    let lineWidth: CGFloat

    var body: some View {
        let extras = AvatarGeometry.extras(for: gender)
        ZStack {
            AvatarBodyShape(gender: gender).stroke(color, lineWidth: lineWidth)
            ForEach(0..<extras.count, id: \.self) { index in
                AvatarExtraShape(frame: extras[index]).stroke(color, lineWidth: lineWidth)
            }
        }
    }
}

// MARK: - Água

/// Água dentro do avatar, com a superfície em movimento.
///
/// - `level`: fração 0...1 da altura preenchida (animável: sobe suavemente).
/// - `phase`: deslocamento da ondulação (avança com o tempo).
/// - `tilt`: inclinação da superfície em pontos, simulando o balanço do
///   líquido dentro de um copo.
/// - `waveHeight`: amplitude da ondulação.
struct WaterSurfaceShape: Shape {
    var level: Double
    var phase: Double = 0
    var tilt: CGFloat = 0
    var waveHeight: CGFloat = 3

    var animatableData: Double {
        get { level }
        set { level = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let clamped = min(max(level, 0), 1)
        guard clamped > 0 else { return Path() }

        // Cheio: a superfície fica acima do topo e o corpo todo é preenchido.
        let margin = clamped >= 1 ? waveHeight + abs(tilt) + 2 : 0
        let baseY = rect.maxY - rect.height * CGFloat(clamped) - margin
        let halfWidth = max(rect.width / 2, 1)

        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        let steps = 24
        for i in 0...steps {
            let x = rect.minX + rect.width * CGFloat(i) / CGFloat(steps)
            let relative = (x - rect.midX) / halfWidth                 // -1...1
            let wave = waveHeight * CGFloat(sin(phase + Double(i) / Double(steps) * 2 * .pi))
            path.addLine(to: CGPoint(x: x, y: baseY + tilt * relative + wave))
        }
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
