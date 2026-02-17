// TB3 iOS — Computed Schedule (mirrors types.ts ComputedSchedule)
// Regenerated in-memory from program + lifts + profile. Not persisted.

import Foundation

struct ComputedSchedule: Codable, Equatable {
    var computedAt: String
    var sourceHash: String
    var weeks: [ComputedWeek]
}

struct ComputedWeek: Codable, Equatable {
    var weekNumber: Int
    var percentage: Int
    var setsRange: [Int]
    var repsPerSet: RepsPerSet
    var sessions: [ComputedSession]

    var label: String { "Week \(weekNumber)" }
    var minSets: Int? { setsRange.first }
    var maxSets: Int? { setsRange.last }
}

struct ComputedSession: Codable, Equatable {
    var sessionNumber: Int
    var exercises: [ComputedExercise]

    var label: String { "Session \(sessionNumber)" }
}

struct ComputedExercise: Codable, Equatable {
    var liftName: String
    var targetWeight: Double
    var plateBreakdown: String
    var plates: [PlateCount]
    var isBodyweight: Bool
    var achievable: Bool
}

struct PlateCount: Codable, Equatable {
    var weight: Double
    var count: Int
}

/// Represents reps per set — either a single value or an array (e.g. Gladiator Week 6: [3,2,1,3,2])
enum RepsPerSet: Codable, Equatable {
    case single(Int)
    case array([Int])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(Int.self) {
            self = .single(value)
        } else if let values = try? container.decode([Int].self) {
            self = .array(values)
        } else {
            throw DecodingError.typeMismatch(
                RepsPerSet.self,
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected Int or [Int]")
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .single(let value):
            try container.encode(value)
        case .array(let values):
            try container.encode(values)
        }
    }

    var firstValue: Int {
        switch self {
        case .single(let v): return v
        case .array(let arr): return arr.first ?? 0
        }
    }

    var allValues: [Int] {
        switch self {
        case .single(let v): return [v]
        case .array(let arr): return arr
        }
    }
}
