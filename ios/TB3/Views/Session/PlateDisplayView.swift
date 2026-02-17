// TB3 iOS — Plate Display View (barbell/belt plate breakdown)

import SwiftUI

struct PlateDisplayView: View {
    let plates: [PlateCount]
    let isBodyweight: Bool

    var body: some View {
        if isBodyweight {
            // No plate display for bodyweight exercises
            EmptyView()
        } else if plates.isEmpty {
            Text("Bar only")
                .font(.caption)
                .foregroundStyle(Color.tb3Muted)
        } else {
            HStack(spacing: 4) {
                ForEach(Array(plates.enumerated()), id: \.offset) { _, plate in
                    plateBadge(plate)
                }
            }
        }
    }

    private func plateBadge(_ plate: PlateCount) -> some View {
        HStack(spacing: 2) {
            if plate.count > 1 {
                Text("\(plate.count)\u{00D7}")
                    .font(.caption2)
                    .foregroundStyle(Color.tb3Muted)
            }
            Text(formatWeight(plate.weight))
                .font(.caption2.bold())
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Color.plateColor(for: plate.weight).opacity(0.2))
        .foregroundStyle(Color.plateColor(for: plate.weight))
        .cornerRadius(4)
    }

    private func formatWeight(_ w: Double) -> String {
        w.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(w))" : String(format: "%.1f", w)
    }
}
