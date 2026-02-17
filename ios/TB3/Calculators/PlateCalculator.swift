// TB3 iOS — Plate Loading Calculator (mirrors calculators/plates.ts)
// Greedy algorithm for barbell (per-side) and belt (total).

import Foundation

struct PlateResult: Equatable {
    var plates: [PlateCount]
    var displayText: String
    var achievable: Bool
    var isBarOnly: Bool
    var isBodyweightOnly: Bool
    var isBelowBar: Bool
    var nearestAchievable: Double?
}

enum PlateCalculator {

    // MARK: - Barbell Plates

    static func calculateBarbellPlates(
        totalWeight: Double,
        barbellWeight: Double,
        inventory: PlateInventory
    ) -> PlateResult {
        // Guard: negative or zero
        if totalWeight <= 0 {
            return PlateResult(
                plates: [], displayText: "Not achievable",
                achievable: false, isBarOnly: false, isBodyweightOnly: false,
                isBelowBar: false
            )
        }

        // Bar only
        if totalWeight == barbellWeight {
            return PlateResult(
                plates: [], displayText: "Bar only",
                achievable: true, isBarOnly: true, isBodyweightOnly: false,
                isBelowBar: false
            )
        }

        // Below bar
        if totalWeight < barbellWeight {
            return PlateResult(
                plates: [], displayText: "Weight is below bar weight",
                achievable: false, isBarOnly: false, isBodyweightOnly: false,
                isBelowBar: true
            )
        }

        let perSide = roundCents((totalWeight - barbellWeight) / 2)
        return greedyPlateCalc(targetWeight: perSide, inventory: inventory, label: "per side")
    }

    // MARK: - Belt Plates (Weighted Pull-ups)

    static func calculateBeltPlates(
        totalWeight: Double,
        inventory: PlateInventory
    ) -> PlateResult {
        if totalWeight <= 0 {
            return PlateResult(
                plates: [], displayText: "Bodyweight only",
                achievable: true, isBarOnly: false, isBodyweightOnly: true,
                isBelowBar: false
            )
        }

        return greedyPlateCalc(targetWeight: totalWeight, inventory: inventory, label: "on belt")
    }

    // MARK: - Greedy Algorithm

    private static func greedyPlateCalc(
        targetWeight: Double,
        inventory: PlateInventory,
        label: String
    ) -> PlateResult {
        let sortedPlates = inventory.plates.sorted { $0.weight > $1.weight }
        var result: [PlateCount] = []
        var remaining = roundCents(targetWeight)

        for plate in sortedPlates {
            guard plate.available > 0, plate.weight <= remaining else { continue }
            let count = min(Int(remaining / plate.weight), plate.available)
            if count > 0 {
                result.append(PlateCount(weight: plate.weight, count: count))
                let used = roundCents(plate.weight * Double(count))
                remaining = roundCents(remaining - used)
            }
        }

        if remaining > 0.001 {
            // Not achievable — find nearest
            let nearest = findNearestAchievable(target: targetWeight, inventory: inventory)
            return PlateResult(
                plates: result,
                displayText: "Not achievable with current plates",
                achievable: false, isBarOnly: false, isBodyweightOnly: false,
                isBelowBar: false, nearestAchievable: nearest
            )
        }

        let parts = result.map { p in
            p.count > 1 ? "\(formatWeight(p.weight)) x\(p.count)" : "\(formatWeight(p.weight))"
        }
        let displayText = parts.isEmpty ? label : "\(parts.joined(separator: "  "))  \(label)"

        return PlateResult(
            plates: result, displayText: displayText,
            achievable: true, isBarOnly: false, isBodyweightOnly: false,
            isBelowBar: false
        )
    }

    // MARK: - Find Nearest Achievable

    private static func findNearestAchievable(target: Double, inventory: PlateInventory) -> Double {
        let sortedPlates = inventory.plates.sorted { $0.weight > $1.weight }

        var offset = 0.25
        while offset <= 50 {
            for dir in [-1.0, 1.0] {
                let candidate = roundCents(target + dir * offset)
                guard candidate >= 0 else { continue }
                var rem = candidate
                for plate in sortedPlates {
                    guard plate.available > 0, plate.weight <= rem else { continue }
                    let count = min(Int(rem / plate.weight), plate.available)
                    rem = roundCents(rem - plate.weight * Double(count))
                }
                if rem < 0.001 { return candidate }
            }
            offset += 0.25
        }
        return 0
    }

    // MARK: - Helpers

    private static func roundCents(_ value: Double) -> Double {
        (value * 100).rounded() / 100
    }

    private static func formatWeight(_ weight: Double) -> String {
        weight.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(weight))
            : String(weight)
    }
}
