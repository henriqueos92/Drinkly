import Foundation

/// Formatação de volumes no padrão brasileiro: "1.250 ml", "2,5 L".
public enum VolumeFormatter {
    private static let locale = Locale(identifier: "pt_BR")

    private static let integerFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = locale
        f.numberStyle = .decimal
        f.usesGroupingSeparator = true
        f.maximumFractionDigits = 0
        return f
    }()

    private static let literFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = locale
        f.numberStyle = .decimal
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 1
        return f
    }()

    private static let lock = NSLock()

    /// "1.250"
    public static func number(_ value: Int) -> String {
        lock.lock(); defer { lock.unlock() }
        return integerFormatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    /// "1.250 ml"
    public static func string(ml: Int) -> String {
        "\(number(ml)) ml"
    }

    /// "1.250 / 2.500 ml"
    public static func progress(consumedMl: Int, goalMl: Int) -> String {
        "\(number(consumedMl)) / \(number(goalMl)) ml"
    }

    /// "2,5 L" — usado em espaços muito pequenos (complicações).
    public static func liters(ml: Int) -> String {
        lock.lock(); defer { lock.unlock() }
        let value = Double(ml) / 1000
        return "\(literFormatter.string(from: NSNumber(value: value)) ?? String(value)) L"
    }

    /// Texto para VoiceOver: "500 mililitros".
    public static func spoken(ml: Int) -> String {
        "\(number(ml)) mililitros"
    }
}
