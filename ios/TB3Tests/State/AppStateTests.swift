// TB3 iOS Tests — AppState (derived state + schedule staleness)

import XCTest
@testable import TB3

final class AppStateTests: XCTestCase {

    // MARK: - Current Lifts Derivation

    func testCurrentLiftsFromMaxTestHistory() {
        let appState = AppState()
        appState.maxTestHistory = [
            TestFixtures.makeMaxTest(liftName: "Squat", weight: 300, reps: 5),
            TestFixtures.makeMaxTest(liftName: "Bench", weight: 200, reps: 5),
        ]

        let lifts = appState.currentLifts
        XCTAssertEqual(lifts.count, 2)
        XCTAssertTrue(lifts.contains(where: { $0.name == "Squat" }))
        XCTAssertTrue(lifts.contains(where: { $0.name == "Bench" }))
    }

    func testCurrentLiftsTakesMostRecentTest() {
        let appState = AppState()
        appState.maxTestHistory = [
            SyncOneRepMaxTest(
                id: generateId(), date: "2024-01-01", liftName: "Squat",
                weight: 200, reps: 5, calculatedMax: 233, maxType: "training",
                workingMax: 233, lastModified: "2024-01-01"
            ),
            SyncOneRepMaxTest(
                id: generateId(), date: "2024-06-01", liftName: "Squat",
                weight: 300, reps: 5, calculatedMax: 350, maxType: "training",
                workingMax: 350, lastModified: "2024-06-01"
            ),
        ]

        let lifts = appState.currentLifts
        XCTAssertEqual(lifts.count, 1)
        let squat = lifts.first { $0.name == "Squat" }
        XCTAssertEqual(squat?.weight, 300)
    }

    func testCurrentLiftsEmpty() {
        let appState = AppState()
        XCTAssertTrue(appState.currentLifts.isEmpty)
    }

    func testCurrentLiftsSortedByName() {
        let appState = AppState()
        appState.maxTestHistory = [
            TestFixtures.makeMaxTest(liftName: "Squat"),
            TestFixtures.makeMaxTest(liftName: "Bench"),
            TestFixtures.makeMaxTest(liftName: "Deadlift"),
        ]

        let names = appState.currentLifts.map(\.name)
        XCTAssertEqual(names, names.sorted())
    }

    func testWeightedPullUpIsBodyweight() {
        let appState = AppState()
        appState.maxTestHistory = [
            TestFixtures.makeMaxTest(liftName: "Weighted Pull-up", weight: 50, reps: 5),
        ]

        let pullUp = appState.currentLifts.first { $0.name == "Weighted Pull-up" }
        XCTAssertTrue(pullUp?.isBodyweight ?? false)
    }

    func testNonPullUpIsNotBodyweight() {
        let appState = AppState()
        appState.maxTestHistory = [
            TestFixtures.makeMaxTest(liftName: "Squat", weight: 300, reps: 5),
        ]

        let squat = appState.currentLifts.first { $0.name == "Squat" }
        XCTAssertFalse(squat?.isBodyweight ?? true)
    }

    // MARK: - Max Type Handling

    func testTrainingMaxType() {
        let appState = AppState()
        appState.maxTestHistory = [
            SyncOneRepMaxTest(
                id: generateId(), date: "2024-01-01", liftName: "Squat",
                weight: 300, reps: 5, calculatedMax: 350, maxType: "training",
                workingMax: 350, lastModified: "2024-01-01"
            ),
        ]

        let squat = appState.currentLifts.first { $0.name == "Squat" }
        XCTAssertNotNil(squat)
        // Training max: workingMax = oneRepMax (no 90% reduction)
        let expectedOneRepMax = OneRepMaxCalculator.calculateOneRepMax(weight: 300, reps: 5)
        XCTAssertEqual(squat!.workingMax, expectedOneRepMax, accuracy: 0.01)
    }

    func testTrueMaxType() {
        let appState = AppState()
        appState.maxTestHistory = [
            SyncOneRepMaxTest(
                id: generateId(), date: "2024-01-01", liftName: "Squat",
                weight: 300, reps: 1, calculatedMax: 300, maxType: "true",
                workingMax: 270, lastModified: "2024-01-01"
            ),
        ]

        let squat = appState.currentLifts.first { $0.name == "Squat" }
        XCTAssertNotNil(squat)
        // True max: workingMax = oneRepMax * 0.9
        let expectedOneRepMax = OneRepMaxCalculator.calculateOneRepMax(weight: 300, reps: 1)
        let expectedWorkingMax = OneRepMaxCalculator.calculateTrainingMax(oneRepMax: expectedOneRepMax)
        XCTAssertEqual(squat!.workingMax, expectedWorkingMax, accuracy: 0.01)
    }

    // MARK: - Schedule Staleness

    func testScheduleStaleWithNoSchedule() {
        let appState = AppState()
        appState.activeProgram = TestFixtures.makeProgram()
        XCTAssertTrue(appState.isScheduleStale())
    }

    func testScheduleStaleWithNoProgram() {
        let appState = AppState()
        appState.activeProgram = nil
        XCTAssertTrue(appState.isScheduleStale())
    }

    func testScheduleNotStaleAfterRegeneration() {
        let appState = AppState()
        appState.activeProgram = TestFixtures.makeProgram()
        appState.maxTestHistory = TestFixtures.standardLifts.map { lift in
            TestFixtures.makeMaxTest(liftName: lift.name, weight: lift.weight, reps: lift.reps)
        }

        appState.regenerateScheduleIfNeeded()
        XCTAssertNotNil(appState.computedSchedule)
        XCTAssertFalse(appState.isScheduleStale())
    }

    func testScheduleStaleAfterLiftChange() {
        let appState = AppState()
        appState.activeProgram = TestFixtures.makeProgram()
        appState.maxTestHistory = [TestFixtures.makeMaxTest(liftName: "Squat", weight: 300, reps: 5)]

        appState.regenerateScheduleIfNeeded()
        XCTAssertFalse(appState.isScheduleStale())

        // Change a lift
        appState.maxTestHistory = [TestFixtures.makeMaxTest(liftName: "Squat", weight: 350, reps: 5)]
        XCTAssertTrue(appState.isScheduleStale())
    }

    // MARK: - Default Profile

    func testDefaultProfile() {
        let appState = AppState()
        XCTAssertEqual(appState.profile.maxType, "training")
        XCTAssertEqual(appState.profile.roundingIncrement, 2.5)
        XCTAssertEqual(appState.profile.barbellWeight, 45)
        XCTAssertEqual(appState.profile.restTimerDefault, 120)
        XCTAssertEqual(appState.profile.soundMode, "on")
        XCTAssertFalse(appState.profile.voiceAnnouncements)
        XCTAssertEqual(appState.profile.unit, "lb")
    }

    // MARK: - Initial State

    func testInitialLoadingState() {
        let appState = AppState()
        XCTAssertTrue(appState.isLoading)
        XCTAssertFalse(appState.isFirstLaunch)
        XCTAssertFalse(appState.isSessionPresented)
        XCTAssertNil(appState.activeSession)
        XCTAssertNil(appState.activeProgram)
        XCTAssertTrue(appState.sessionHistory.isEmpty)
        XCTAssertTrue(appState.maxTestHistory.isEmpty)
    }
}
