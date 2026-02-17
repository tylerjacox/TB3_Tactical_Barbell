// TB3 iOS — Plate Display View (barbell/belt diagram matching web PlateDisplay.tsx)

import SwiftUI

// MARK: - Plate Dimensions (matching web constants)

private let plateHeightPct: [Double: CGFloat] = [
    45: 100, 35: 88, 25: 76, 10: 58, 5: 46, 2.5: 38, 1.25: 32,
]
private let plateThickness: [Double: CGFloat] = [
    45: 10, 35: 9, 25: 8, 10: 6, 5: 5, 2.5: 4, 1.25: 3,
]
private let beltPlateWidth: [Double: CGFloat] = [
    45: 40, 35: 36, 25: 32, 10: 26, 5: 22, 2.5: 18, 1.25: 16,
]

// MARK: - PlateDisplayView

struct PlateDisplayView: View {
    let result: PlateResult
    let isBodyweight: Bool
    var scale: CGFloat = 1.0

    var body: some View {
        if result.isBarOnly {
            Text("Bar only")
                .font(.caption)
                .foregroundStyle(Color.tb3Muted)
        } else if result.isBodyweightOnly {
            Text("Bodyweight only")
                .font(.caption)
                .foregroundStyle(Color.tb3Muted)
        } else if result.isBelowBar {
            Text("Weight is below bar weight")
                .font(.caption)
                .foregroundStyle(Color.tb3Error)
        } else if !result.achievable {
            VStack(spacing: 2) {
                Text("Not achievable with current plates")
                    .font(.caption)
                    .foregroundStyle(Color.tb3Error)
                if let nearest = result.nearestAchievable, nearest > 0 {
                    Text("(nearest: \(Int(nearest)) lb)")
                        .font(.caption2)
                        .foregroundStyle(Color.tb3Muted)
                }
            }
        } else if !result.plates.isEmpty {
            VStack(spacing: 6 * scale) {
                if isBodyweight {
                    BeltVisual(plates: expandPlates(result.plates), scale: scale)
                } else {
                    BarbellVisual(plates: expandPlates(result.plates), scale: scale)
                }
                PlateSummary(
                    plates: result.plates,
                    label: isBodyweight ? "on belt" : "per side",
                    scale: scale
                )
            }
        }
    }

    private func expandPlates(_ grouped: [PlateCount]) -> [Double] {
        var expanded: [Double] = []
        for p in grouped {
            for _ in 0..<p.count {
                expanded.append(p.weight)
            }
        }
        return expanded
    }
}

// MARK: - Barbell Visual

private struct BarbellVisual: View {
    let plates: [Double]
    var scale: CGFloat = 1.0

    private var maxHeight: CGFloat { 44 * scale }
    private var barHeight: CGFloat { 6 * scale }

    var body: some View {
        HStack(spacing: 1 * scale) {
            // Left plates (reversed: heaviest near collar)
            HStack(spacing: 1 * scale) {
                ForEach(Array(plates.reversed().enumerated()), id: \.offset) { _, weight in
                    plateRect(weight)
                }
            }

            // Left collar
            collarView

            // Bar
            Rectangle()
                .fill(Color(white: 0.53))
                .frame(width: 48 * scale, height: barHeight)

            // Right collar
            collarView

            // Right plates (heaviest near collar)
            HStack(spacing: 1 * scale) {
                ForEach(Array(plates.enumerated()), id: \.offset) { _, weight in
                    plateRect(weight)
                }
            }
        }
        .frame(height: maxHeight + 4 * scale)
    }

    private func plateRect(_ weight: Double) -> some View {
        let h = (plateHeightPct[weight] ?? 50) / 100 * maxHeight
        let w = (plateThickness[weight] ?? 6) * scale
        let color = Color.plateColor(for: weight)
        let cr = 1.5 * scale
        return RoundedRectangle(cornerRadius: cr)
            .fill(color)
            .overlay(RoundedRectangle(cornerRadius: cr).stroke(color.opacity(0.5), lineWidth: 0.5))
            .frame(width: w, height: h)
    }

    private var collarView: some View {
        RoundedRectangle(cornerRadius: 1 * scale)
            .fill(Color(white: 0.4))
            .frame(width: 6 * scale, height: 14 * scale)
    }
}

// MARK: - Belt Visual

private struct BeltVisual: View {
    let plates: [Double]
    var scale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 0) {
            // Chain
            Rectangle()
                .fill(Color.clear)
                .frame(width: 2 * scale, height: 16 * scale)
                .overlay(
                    VStack(spacing: 2 * scale) {
                        ForEach(0..<4, id: \.self) { _ in
                            Rectangle()
                                .fill(Color(white: 0.53))
                                .frame(width: 2 * scale, height: 2 * scale)
                        }
                    }
                )

            // Plates stacked vertically (heaviest on top)
            VStack(spacing: 1 * scale) {
                ForEach(Array(plates.enumerated()), id: \.offset) { _, weight in
                    let w = (beltPlateWidth[weight] ?? 24) * scale
                    let h = (plateThickness[weight] ?? 6) * scale
                    let color = Color.plateColor(for: weight)
                    let cr = 1.5 * scale
                    RoundedRectangle(cornerRadius: cr)
                        .fill(color)
                        .overlay(RoundedRectangle(cornerRadius: cr).stroke(color.opacity(0.5), lineWidth: 0.5))
                        .frame(width: w, height: h)
                }
            }

            // Pin
            Rectangle()
                .fill(Color(white: 0.53))
                .frame(width: 2 * scale, height: 6 * scale)
        }
    }
}

// MARK: - Plate Summary (legend)

private struct PlateSummary: View {
    let plates: [PlateCount]
    let label: String
    var scale: CGFloat = 1.0

    // Legend text scales more gently than the diagram
    private var legendScale: CGFloat { min(scale, 1.6) }

    var body: some View {
        HStack(spacing: 8 * legendScale) {
            ForEach(Array(plates.enumerated()), id: \.offset) { _, plate in
                HStack(spacing: 4 * legendScale) {
                    Circle()
                        .fill(Color.plateColor(for: plate.weight))
                        .overlay(Circle().stroke(Color.plateColor(for: plate.weight).opacity(0.5), lineWidth: 0.5))
                        .frame(width: 8 * legendScale, height: 8 * legendScale)
                    Text(plate.count > 1
                        ? "\(formatWeight(plate.weight)) x\(plate.count)"
                        : formatWeight(plate.weight))
                        .font(.system(size: 12 * legendScale).monospacedDigit())
                        .foregroundStyle(Color.tb3Text)
                }
            }

            Text(label)
                .font(.system(size: 11 * legendScale))
                .foregroundStyle(Color.tb3Muted)
        }
    }

    private func formatWeight(_ w: Double) -> String {
        w.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(w))" : String(format: "%.1f", w)
    }
}
