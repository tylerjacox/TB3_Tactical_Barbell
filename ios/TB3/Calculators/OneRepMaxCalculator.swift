// TB3 iOS — 1RM Calculator (mirrors calculators/oneRepMax.ts)
// Epley formula: weight * (1 + reps / 30)

import Foundation

enum OneRepMaxCalculator {

    /// Calculate one-rep max using Epley formula
    static func calculateOneRepMax(weight: Double, reps: Int) -> Double {
        guard reps > 0, weight > 0 else { return 0 }
        if reps == 1 { return weight }
        return weight * (1 + Double(reps) / 30)
    }

    /// Training max = 90% of 1RM
    static func calculateTrainingMax(oneRepMax: Double) -> Double {
        oneRepMax * 0.9
    }

    /// Round weight to nearest increment (2.5 or 5)
    static func roundWeight(_ weight: Double, increment: Double) -> Double {
        (weight / increment).rounded() * increment
    }

    /// Calculate weight at a percentage of working max, rounded
    static func calculatePercentageWeight(workingMax: Double, percentage: Int, roundingIncrement: Double) -> Double {
        roundWeight(workingMax * (Double(percentage) / 100), increment: roundingIncrement)
    }

    /// Generate percentage table (65-100%) for a working max
    static func calculatePercentageTable(workingMax: Double, roundingIncrement: Double) -> [PercentageRow] {
        let percentages = [65, 70, 75, 80, 85, 90, 95, 100]
        return percentages.map { pct in
            PercentageRow(
                percentage: pct,
                weight: calculatePercentageWeight(workingMax: workingMax, percentage: pct, roundingIncrement: roundingIncrement)
            )
        }
    }
}

struct PercentageRow: Equatable {
    let percentage: Int
    let weight: Double
}
