import SwiftUI
import DrinklyCore

/// "08:30 — Água — 500 ml"
struct RecordRow: View {
    let record: DrinkRecord

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "pt_BR")
        f.dateFormat = "HH:mm"
        return f
    }()

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: record.type.symbolName)
                .foregroundColor(record.type.tint)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 0) {
                Text(record.type.displayName)
                    .font(Theme.rounded(.footnote, weight: .medium))
                    .lineLimit(1)
                Text(Self.timeFormatter.string(from: record.timestamp))
                    .font(.footnote)
                    .foregroundColor(Theme.secondaryText)
            }
            Spacer(minLength: 2)
            Text(VolumeFormatter.string(ml: record.volumeMl))
                .font(Theme.rounded(.footnote))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(Self.timeFormatter.string(from: record.timestamp)), \(record.type.displayName), \(VolumeFormatter.spoken(ml: record.volumeMl))")
    }
}
