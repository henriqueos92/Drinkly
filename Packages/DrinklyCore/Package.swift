// swift-tools-version:5.9
import PackageDescription

// Núcleo de regras de negócio do Drinkly.
// Não depende de SwiftUI/UIKit/WatchKit: compila em watchOS, iOS, macOS e Linux,
// o que permite reutilizá-lo no app do relógio, na extensão de widgets e em um
// futuro app de iPhone — e rodar os testes com `swift test` fora do Xcode.
let package = Package(
    name: "DrinklyCore",
    platforms: [
        .watchOS(.v8),
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(name: "DrinklyCore", targets: ["DrinklyCore"])
    ],
    targets: [
        .target(name: "DrinklyCore"),
        .testTarget(name: "DrinklyCoreTests", dependencies: ["DrinklyCore"])
    ]
)
