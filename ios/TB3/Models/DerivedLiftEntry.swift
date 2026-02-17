// TB3 iOS — Derived Lift Entry (mirrors types.ts DerivedLiftEntry)
// Computed from maxTestHistory — not persisted directly.

import Foundation

struct DerivedLiftEntry: Equatable, Identifiable {
    var id: String { name }
    var name: String
    var weight: Double
    var reps: Int
    var oneRepMax: Double
    var workingMax: Double
    var isBodyweight: Bool
    var testDate: String
}
