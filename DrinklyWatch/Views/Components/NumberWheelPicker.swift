import SwiftUI

/// Picker em roda (girável pela Digital Crown) para valores inteiros.
struct NumberWheelPicker: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    var step: Int = 1
    let unit: String
    var height: CGFloat = 70

    var body: some View {
        Picker(title, selection: $value) {
            ForEach(Array(stride(from: range.lowerBound, through: range.upperBound, by: step)), id: \.self) { number in
                Text("\(number) \(unit)").tag(number)
            }
        }
        .pickerStyle(.wheel)
        .frame(height: height)
        .accessibilityValue("\(value) \(unit)")
    }
}

/// Picker de horário em intervalos de 30 minutos (DatePicker só existe a
/// partir do watchOS 10).
struct TimeOfDayPicker: View {
    let title: String
    @Binding var minuteOfDay: Int
    var allowsEndOfDay = false

    var body: some View {
        let last = allowsEndOfDay ? 48 : 47
        Picker(title, selection: $minuteOfDay) {
            ForEach(0...last, id: \.self) { slot in
                Text(slot == 48 ? "24:00" : String(format: "%02d:%02d", slot / 2, (slot % 2) * 30))
                    .tag(slot * 30)
            }
        }
        .pickerStyle(.wheel)
        .frame(height: 60)
    }
}
