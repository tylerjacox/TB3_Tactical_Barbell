// TB3 iOS Tests — Test Fixtures (mirrors __tests__/fixtures.ts)

import Foundation
@testable import TB3

enum TestFixtures {

    static func makeProfile(
        maxType: String = "training",
        roundingIncrement: Double = 2.5,
        barbellWeight: Double = 45,
        restTimerDefault: Int = 120
    ) -> SyncProfile {
        SyncProfile(
            maxType: maxType,
            roundingIncrement: roundingIncrement,
            barbellWeight: barbellWeight,
            plateInventoryBarbell: DEFAULT_PLATE_INVENTORY_BARBELL,
            plateInventoryBelt: DEFAULT_PLATE_INVENTORY_BELT,
            restTimerDefault: restTimerDefault,
            soundMode: "on",
            voiceAnnouncements: false,
            voiceName: nil,
            theme: "dark",
            unit: "lb",
            lastModified: "2024-01-01T00:00:00Z"
        )
    }

    static func makeLift(
        name: String = "Squat",
        weight: Double = 300,
        reps: Int = 5
    ) -> DerivedLiftEntry {
        let oneRepMax = OneRepMaxCalculator.calculateOneRepMax(weight: weight, reps: reps)
        let workingMax = OneRepMaxCalculator.calculateTrainingMax(oneRepMax: oneRepMax)
        return DerivedLiftEntry(
            name: name,
            weight: weight,
            reps: reps,
            oneRepMax: oneRepMax,
            workingMax: workingMax,
            isBodyweight: name == "Weighted Pull-up",
            testDate: "2024-01-01T00:00:00Z"
        )
    }

    static func makeProgram(
        templateId: String = "operator",
        liftSelections: [String: [String]] = [:]
    ) -> SyncActiveProgram {
        SyncActiveProgram(
            templateId: templateId,
            startDate: "2024-01-01",
            currentWeek: 1,
            currentSession: 1,
            liftSelections: liftSelections,
            lastModified: "2024-01-01T00:00:00Z"
        )
    }

    static func makeMaxTest(
        liftName: String = "Squat",
        weight: Double = 300,
        reps: Int = 5
    ) -> SyncOneRepMaxTest {
        let oneRepMax = OneRepMaxCalculator.calculateOneRepMax(weight: weight, reps: reps)
        let workingMax = OneRepMaxCalculator.calculateTrainingMax(oneRepMax: oneRepMax)
        return SyncOneRepMaxTest(
            id: generateId(),
            date: "2024-01-01",
            liftName: liftName,
            weight: weight,
            reps: reps,
            calculatedMax: oneRepMax,
            maxType: "training",
            workingMax: workingMax,
            lastModified: "2024-01-01T00:00:00Z"
        )
    }

    static func makeInventory(plates: [(Double, Int)] = [(45, 4), (35, 1), (25, 1), (10, 2), (5, 1), (2.5, 1), (1.25, 1)]) -> PlateInventory {
        PlateInventory(plates: plates.map { PlateEntry(weight: $0.0, available: $0.1) })
    }

    static func makeBeltInventory(plates: [(Double, Int)] = [(45, 2), (35, 1), (25, 1), (10, 2), (5, 1), (2.5, 1), (1.25, 1)]) -> PlateInventory {
        PlateInventory(plates: plates.map { PlateEntry(weight: $0.0, available: $0.1) })
    }

    /// Standard set of 5 lifts for testing
    static let standardLifts: [DerivedLiftEntry] = [
        makeLift(name: "Squat", weight: 300, reps: 5),
        makeLift(name: "Bench", weight: 200, reps: 5),
        makeLift(name: "Deadlift", weight: 350, reps: 5),
        makeLift(name: "Military Press", weight: 135, reps: 5),
        makeLift(name: "Weighted Pull-up", weight: 50, reps: 5),
    ]
}
