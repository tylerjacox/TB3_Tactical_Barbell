// TB3 iOS — Template Definition (mirrors templates/definitions.ts interfaces)

import Foundation

struct TemplateDef: Equatable {
    let id: TemplateId
    let name: String
    let description: String
    let durationWeeks: Int
    let sessionsPerWeek: Int
    let requiresLiftSelection: Bool
    let liftSlots: [LiftSlotDef]?
    let hasSetRange: Bool
    let hideRestTimer: Bool
    let weeks: [WeekDef]
    let sessionDefs: [SessionDef]
    let recommendedDays: [Int]
}

struct WeekDef: Equatable {
    let weekNumber: Int
    let percentage: Int
    let setsRange: [Int] // [min, max]
    let repsPerSet: RepsPerSet
}

struct SessionDef: Equatable {
    let sessionNumber: Int
    let lifts: [String]?
    let liftSource: LiftSource?
    let repsOverride: RepsPerSet?
    let setsOverride: [String: Int]? // Per-lift fixed set count (e.g. ["Deadlift": 3])

    init(sessionNumber: Int, lifts: [String]? = nil, liftSource: LiftSource? = nil, repsOverride: RepsPerSet? = nil, setsOverride: [String: Int]? = nil) {
        self.sessionNumber = sessionNumber
        self.lifts = lifts
        self.liftSource = liftSource
        self.repsOverride = repsOverride
        self.setsOverride = setsOverride
    }
}

enum LiftSource: String, Equatable {
    case fixed
    case cluster
    case a = "A"
    case b = "B"
}

struct LiftSlotDef: Equatable {
    let cluster: String
    let label: String
    let minLifts: Int
    let maxLifts: Int
    let defaults: [String]
}
