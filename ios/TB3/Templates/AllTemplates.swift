// TB3 iOS — All 7 Template Definitions (mirrors templates/definitions.ts data)

import Foundation

enum Templates {

    // MARK: - Operator

    static let `operator` = TemplateDef(
        id: .operator,
        name: "Operator",
        description: "3 strength sessions/week. Fixed lifts. 6-week cycle.",
        durationWeeks: 6,
        sessionsPerWeek: 3,
        requiresLiftSelection: false,
        liftSlots: nil,
        hasSetRange: true,
        hideRestTimer: false,
        weeks: [
            WeekDef(weekNumber: 1, percentage: 70, setsRange: [3, 5], repsPerSet: .single(5)),
            WeekDef(weekNumber: 2, percentage: 80, setsRange: [3, 5], repsPerSet: .single(5)),
            WeekDef(weekNumber: 3, percentage: 90, setsRange: [3, 4], repsPerSet: .single(3)),
            WeekDef(weekNumber: 4, percentage: 75, setsRange: [3, 5], repsPerSet: .single(5)),
            WeekDef(weekNumber: 5, percentage: 85, setsRange: [3, 5], repsPerSet: .single(3)),
            WeekDef(weekNumber: 6, percentage: 95, setsRange: [3, 4], repsPerSet: .array([1, 2])),
        ],
        sessionDefs: [
            SessionDef(sessionNumber: 1, lifts: ["Squat", "Bench", "Weighted Pull-up"], liftSource: .fixed, repsOverride: nil),
            SessionDef(sessionNumber: 2, lifts: ["Squat", "Bench", "Weighted Pull-up"], liftSource: .fixed, repsOverride: nil),
            SessionDef(sessionNumber: 3, lifts: ["Squat", "Bench", "Deadlift"], liftSource: .fixed, repsOverride: nil),
        ],
        recommendedDays: [3]
    )

    // MARK: - Zulu

    static let zulu = TemplateDef(
        id: .zulu,
        name: "Zulu",
        description: "4 strength sessions/week. A/B split with two intensity levels per week. 6-week cycle.",
        durationWeeks: 6,
        sessionsPerWeek: 4,
        requiresLiftSelection: true,
        liftSlots: [
            LiftSlotDef(cluster: "A", label: "A Day", minLifts: 2, maxLifts: 3, defaults: ["Military Press", "Squat", "Weighted Pull-up"]),
            LiftSlotDef(cluster: "B", label: "B Day", minLifts: 2, maxLifts: 3, defaults: ["Bench", "Deadlift"]),
        ],
        hasSetRange: false,
        hideRestTimer: false,
        weeks: [
            WeekDef(weekNumber: 1, percentage: 70, setsRange: [3, 3], repsPerSet: .single(5)),
            WeekDef(weekNumber: 2, percentage: 80, setsRange: [3, 3], repsPerSet: .single(5)),
            WeekDef(weekNumber: 3, percentage: 90, setsRange: [3, 3], repsPerSet: .single(3)),
            WeekDef(weekNumber: 4, percentage: 70, setsRange: [3, 3], repsPerSet: .single(5)),
            WeekDef(weekNumber: 5, percentage: 80, setsRange: [3, 3], repsPerSet: .single(5)),
            WeekDef(weekNumber: 6, percentage: 90, setsRange: [3, 3], repsPerSet: .single(3)),
        ],
        sessionDefs: [
            SessionDef(sessionNumber: 1, lifts: nil, liftSource: .a, repsOverride: nil),
            SessionDef(sessionNumber: 2, lifts: nil, liftSource: .b, repsOverride: nil),
            SessionDef(sessionNumber: 3, lifts: nil, liftSource: .a, repsOverride: nil),
            SessionDef(sessionNumber: 4, lifts: nil, liftSource: .b, repsOverride: nil),
        ],
        recommendedDays: [4]
    )

    /// Zulu cluster percentages per week (sessions 1-2 = clusterOne, sessions 3-4 = clusterTwo)
    static let zuluClusterPercentages: [Int: (clusterOne: Int, clusterTwo: Int)] = [
        1: (70, 75),
        2: (80, 80),
        3: (90, 90),
        4: (70, 75),
        5: (80, 80),
        6: (90, 90),
    ]

    // MARK: - Fighter

    static let fighter = TemplateDef(
        id: .fighter,
        name: "Fighter",
        description: "Minimal lifting. 2 sessions/week. For heavy conditioning schedules. 6-week cycle.",
        durationWeeks: 6,
        sessionsPerWeek: 2,
        requiresLiftSelection: true,
        liftSlots: [
            LiftSlotDef(cluster: "cluster", label: "Lifts", minLifts: 2, maxLifts: 3, defaults: ["Squat", "Bench"]),
        ],
        hasSetRange: true,
        hideRestTimer: false,
        weeks: [
            WeekDef(weekNumber: 1, percentage: 75, setsRange: [3, 5], repsPerSet: .single(5)),
            WeekDef(weekNumber: 2, percentage: 80, setsRange: [3, 5], repsPerSet: .single(5)),
            WeekDef(weekNumber: 3, percentage: 90, setsRange: [3, 5], repsPerSet: .single(3)),
            WeekDef(weekNumber: 4, percentage: 75, setsRange: [3, 5], repsPerSet: .single(5)),
            WeekDef(weekNumber: 5, percentage: 80, setsRange: [3, 5], repsPerSet: .single(5)),
            WeekDef(weekNumber: 6, percentage: 90, setsRange: [3, 5], repsPerSet: .single(3)),
        ],
        sessionDefs: [
            SessionDef(sessionNumber: 1, lifts: nil, liftSource: .cluster, repsOverride: nil),
            SessionDef(sessionNumber: 2, lifts: nil, liftSource: .cluster, repsOverride: nil),
        ],
        recommendedDays: [2]
    )

    // MARK: - Gladiator

    static let gladiator = TemplateDef(
        id: .gladiator,
        name: "Gladiator",
        description: "High volume. 3 sessions/week. All lifts every session. 5x5 base. 6-week cycle.",
        durationWeeks: 6,
        sessionsPerWeek: 3,
        requiresLiftSelection: true,
        liftSlots: [
            LiftSlotDef(cluster: "cluster", label: "Lifts", minLifts: 2, maxLifts: 4, defaults: ["Squat", "Bench", "Deadlift"]),
        ],
        hasSetRange: false,
        hideRestTimer: false,
        weeks: [
            WeekDef(weekNumber: 1, percentage: 70, setsRange: [5, 5], repsPerSet: .single(5)),
            WeekDef(weekNumber: 2, percentage: 80, setsRange: [5, 5], repsPerSet: .single(5)),
            WeekDef(weekNumber: 3, percentage: 90, setsRange: [5, 5], repsPerSet: .single(3)),
            WeekDef(weekNumber: 4, percentage: 75, setsRange: [5, 5], repsPerSet: .single(5)),
            WeekDef(weekNumber: 5, percentage: 85, setsRange: [5, 5], repsPerSet: .single(5)),
            WeekDef(weekNumber: 6, percentage: 95, setsRange: [5, 5], repsPerSet: .array([3, 2, 1, 3, 2])),
        ],
        sessionDefs: [
            SessionDef(sessionNumber: 1, lifts: nil, liftSource: .cluster, repsOverride: nil),
            SessionDef(sessionNumber: 2, lifts: nil, liftSource: .cluster, repsOverride: nil),
            SessionDef(sessionNumber: 3, lifts: nil, liftSource: .cluster, repsOverride: nil),
        ],
        recommendedDays: [3]
    )

    // MARK: - Mass Protocol

    static let massProtocol = TemplateDef(
        id: .massProtocol,
        name: "Mass Protocol",
        description: "Hypertrophy focus. 3 sessions/week. All lifts every session. No rest minimums. 6-week cycle.",
        durationWeeks: 6,
        sessionsPerWeek: 3,
        requiresLiftSelection: true,
        liftSlots: [
            LiftSlotDef(cluster: "cluster", label: "Lifts", minLifts: 2, maxLifts: 4, defaults: ["Squat", "Bench", "Deadlift"]),
        ],
        hasSetRange: false,
        hideRestTimer: true,
        weeks: [
            WeekDef(weekNumber: 1, percentage: 75, setsRange: [4, 4], repsPerSet: .single(6)),
            WeekDef(weekNumber: 2, percentage: 80, setsRange: [4, 4], repsPerSet: .single(5)),
            WeekDef(weekNumber: 3, percentage: 90, setsRange: [4, 4], repsPerSet: .single(3)),
            WeekDef(weekNumber: 4, percentage: 75, setsRange: [4, 4], repsPerSet: .single(6)),
            WeekDef(weekNumber: 5, percentage: 85, setsRange: [4, 4], repsPerSet: .single(4)),
            WeekDef(weekNumber: 6, percentage: 90, setsRange: [4, 4], repsPerSet: .single(3)),
        ],
        sessionDefs: [
            SessionDef(sessionNumber: 1, lifts: nil, liftSource: .cluster, repsOverride: nil),
            SessionDef(sessionNumber: 2, lifts: nil, liftSource: .cluster, repsOverride: nil),
            SessionDef(sessionNumber: 3, lifts: nil, liftSource: .cluster, repsOverride: nil),
        ],
        recommendedDays: [3]
    )

    // MARK: - Mass Strength

    static let massStrength = TemplateDef(
        id: .massStrength,
        name: "Mass Strength",
        description: "Hypertrophy + strength. 4 tracked sessions per week with a dedicated deadlift day. 3-week cycle.",
        durationWeeks: 3,
        sessionsPerWeek: 4,
        requiresLiftSelection: false,
        liftSlots: nil,
        hasSetRange: false,
        hideRestTimer: false,
        weeks: [
            WeekDef(weekNumber: 1, percentage: 65, setsRange: [4, 4], repsPerSet: .single(8)),
            WeekDef(weekNumber: 2, percentage: 75, setsRange: [4, 4], repsPerSet: .single(6)),
            WeekDef(weekNumber: 3, percentage: 80, setsRange: [4, 4], repsPerSet: .single(3)),
        ],
        sessionDefs: [
            SessionDef(sessionNumber: 1, lifts: ["Squat", "Bench", "Weighted Pull-up"], liftSource: .fixed, repsOverride: nil),
            SessionDef(sessionNumber: 2, lifts: ["Squat", "Bench", "Weighted Pull-up"], liftSource: .fixed, repsOverride: nil),
            SessionDef(sessionNumber: 3, lifts: ["Squat", "Bench", "Weighted Pull-up"], liftSource: .fixed, repsOverride: nil),
            SessionDef(sessionNumber: 4, lifts: ["Deadlift"], liftSource: .fixed, repsOverride: nil),
        ],
        recommendedDays: [3]
    )

    /// Mass Strength deadlift day overrides per week
    static let massStrengthDLWeeks: [Int: (sets: Int, reps: Int)] = [
        1: (4, 5),
        2: (4, 5),
        3: (1, 3),
    ]

    // MARK: - Grey Man

    static let greyMan = TemplateDef(
        id: .greyMan,
        name: "Grey Man",
        description: "Low profile. 3 sessions/week. All lifts every session. 12-week cycle with progressive intensification.",
        durationWeeks: 12,
        sessionsPerWeek: 3,
        requiresLiftSelection: true,
        liftSlots: [
            LiftSlotDef(cluster: "cluster", label: "Lifts", minLifts: 2, maxLifts: 4, defaults: ["Squat", "Bench", "Deadlift"]),
        ],
        hasSetRange: false,
        hideRestTimer: false,
        weeks: [
            WeekDef(weekNumber: 1, percentage: 70, setsRange: [3, 3], repsPerSet: .single(6)),
            WeekDef(weekNumber: 2, percentage: 80, setsRange: [3, 3], repsPerSet: .single(5)),
            WeekDef(weekNumber: 3, percentage: 90, setsRange: [3, 3], repsPerSet: .single(3)),
            WeekDef(weekNumber: 4, percentage: 70, setsRange: [3, 3], repsPerSet: .single(6)),
            WeekDef(weekNumber: 5, percentage: 80, setsRange: [3, 3], repsPerSet: .single(5)),
            WeekDef(weekNumber: 6, percentage: 90, setsRange: [3, 3], repsPerSet: .single(3)),
            WeekDef(weekNumber: 7, percentage: 75, setsRange: [3, 3], repsPerSet: .single(6)),
            WeekDef(weekNumber: 8, percentage: 85, setsRange: [3, 3], repsPerSet: .single(5)),
            WeekDef(weekNumber: 9, percentage: 95, setsRange: [3, 3], repsPerSet: .single(1)),
            WeekDef(weekNumber: 10, percentage: 75, setsRange: [3, 3], repsPerSet: .single(6)),
            WeekDef(weekNumber: 11, percentage: 85, setsRange: [3, 3], repsPerSet: .single(5)),
            WeekDef(weekNumber: 12, percentage: 95, setsRange: [3, 3], repsPerSet: .single(1)),
        ],
        sessionDefs: [
            SessionDef(sessionNumber: 1, lifts: nil, liftSource: .cluster, repsOverride: nil),
            SessionDef(sessionNumber: 2, lifts: nil, liftSource: .cluster, repsOverride: nil),
            SessionDef(sessionNumber: 3, lifts: nil, liftSource: .cluster, repsOverride: nil),
        ],
        recommendedDays: [3]
    )

    // MARK: - All Templates

    static let all: [TemplateDef] = [
        `operator`, zulu, fighter, gladiator, massProtocol, massStrength, greyMan,
    ]

    static func get(id: TemplateId) -> TemplateDef? {
        all.first { $0.id == id }
    }

    static func get(id: String) -> TemplateDef? {
        guard let templateId = TemplateId(rawValue: id) else { return nil }
        return get(id: templateId)
    }

    static func getForDays(_ days: Int) -> [TemplateDef] {
        switch days {
        case 2: return [fighter]
        case 3: return [`operator`, gladiator, massProtocol, greyMan]
        case 4: return [zulu]
        default: return all
        }
    }
}
