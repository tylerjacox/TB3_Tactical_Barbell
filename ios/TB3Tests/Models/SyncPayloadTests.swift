// TB3 iOS Tests — Sync Payloads (Codable round-trip + compatibility)

import XCTest
@testable import TB3

final class SyncPayloadTests: XCTestCase {

    // MARK: - SyncProfile

    func testProfileRoundTrip() throws {
        let profile = TestFixtures.makeProfile()
        let data = try JSONEncoder().encode(profile)
        let decoded = try JSONDecoder().decode(SyncProfile.self, from: data)
        XCTAssertEqual(profile, decoded)
    }

    func testProfileDefaultValues() {
        let profile = TestFixtures.makeProfile()
        XCTAssertEqual(profile.barbellWeight, 45)
        XCTAssertEqual(profile.roundingIncrement, 2.5)
        XCTAssertEqual(profile.soundMode, "on")
        XCTAssertFalse(profile.voiceAnnouncements)
        XCTAssertNil(profile.voiceName)
    }

    // MARK: - SyncActiveProgram

    func testProgramRoundTrip() throws {
        let program = TestFixtures.makeProgram(
            templateId: "zulu",
            liftSelections: ["A": ["Squat", "Bench"], "B": ["Deadlift"]]
        )
        let data = try JSONEncoder().encode(program)
        let decoded = try JSONDecoder().decode(SyncActiveProgram.self, from: data)
        XCTAssertEqual(program, decoded)
    }

    func testProgramLiftSelections() {
        let program = TestFixtures.makeProgram(
            templateId: "zulu",
            liftSelections: ["A": ["Squat", "Bench"], "B": ["Deadlift"]]
        )
        XCTAssertEqual(program.liftSelections["A"], ["Squat", "Bench"])
        XCTAssertEqual(program.liftSelections["B"], ["Deadlift"])
    }

    // MARK: - SyncOneRepMaxTest

    func testMaxTestRoundTrip() throws {
        let test = TestFixtures.makeMaxTest(liftName: "Squat", weight: 300, reps: 5)
        let data = try JSONEncoder().encode(test)
        let decoded = try JSONDecoder().decode(SyncOneRepMaxTest.self, from: data)
        XCTAssertEqual(test, decoded)
    }

    func testMaxTestCalculatedValues() {
        let test = TestFixtures.makeMaxTest(liftName: "Bench", weight: 200, reps: 5)
        let expectedMax = OneRepMaxCalculator.calculateOneRepMax(weight: 200, reps: 5)
        XCTAssertEqual(test.calculatedMax, expectedMax, accuracy: 0.01)
    }

    // MARK: - SyncSessionLog

    func testSessionLogRoundTrip() throws {
        let log = SyncSessionLog(
            id: generateId(),
            date: "2024-01-15",
            templateId: "operator",
            week: 1,
            sessionNumber: 1,
            status: "completed",
            startedAt: "2024-01-15T10:00:00Z",
            completedAt: "2024-01-15T11:00:00Z",
            exercises: [
                SyncExerciseLog(
                    liftName: "Squat",
                    targetWeight: 200,
                    actualWeight: 200,
                    sets: [
                        SyncExerciseSet(targetReps: 5, actualReps: 5, completed: true),
                        SyncExerciseSet(targetReps: 5, actualReps: 5, completed: true),
                    ],
                    durationSeconds: 300
                )
            ],
            notes: "",
            durationSeconds: 3600,
            lastModified: "2024-01-15T11:00:00Z"
        )

        let data = try JSONEncoder().encode(log)
        let decoded = try JSONDecoder().decode(SyncSessionLog.self, from: data)
        XCTAssertEqual(log, decoded)
    }

    // MARK: - RepsPerSet Encoding

    func testRepsPerSetSingleRoundTrip() throws {
        let reps: RepsPerSet = .single(5)
        let data = try JSONEncoder().encode(reps)
        let decoded = try JSONDecoder().decode(RepsPerSet.self, from: data)
        XCTAssertEqual(reps, decoded)
    }

    func testRepsPerSetArrayRoundTrip() throws {
        let reps: RepsPerSet = .array([3, 2, 1, 3, 2])
        let data = try JSONEncoder().encode(reps)
        let decoded = try JSONDecoder().decode(RepsPerSet.self, from: data)
        XCTAssertEqual(reps, decoded)
    }

    func testRepsPerSetSingleEncodesAsInt() throws {
        let reps: RepsPerSet = .single(5)
        let data = try JSONEncoder().encode(reps)
        let json = String(data: data, encoding: .utf8)
        XCTAssertEqual(json, "5")
    }

    func testRepsPerSetArrayEncodesAsArray() throws {
        let reps: RepsPerSet = .array([3, 2, 1])
        let data = try JSONEncoder().encode(reps)
        let json = String(data: data, encoding: .utf8)
        XCTAssertEqual(json, "[3,2,1]")
    }

    func testRepsPerSetFirstValue() {
        XCTAssertEqual(RepsPerSet.single(5).firstValue, 5)
        XCTAssertEqual(RepsPerSet.array([3, 2, 1]).firstValue, 3)
        XCTAssertEqual(RepsPerSet.array([]).firstValue, 0)
    }

    func testRepsPerSetAllValues() {
        XCTAssertEqual(RepsPerSet.single(5).allValues, [5])
        XCTAssertEqual(RepsPerSet.array([3, 2, 1]).allValues, [3, 2, 1])
    }

    // MARK: - ExportedAppData

    func testExportDataRoundTrip() throws {
        let exportData = ExportedAppData(
            tb3_export: true,
            exportedAt: Date.iso8601Now(),
            appVersion: "1.0.0",
            schemaVersion: CURRENT_SCHEMA_VERSION,
            profile: TestFixtures.makeProfile(),
            activeProgram: TestFixtures.makeProgram(),
            sessionHistory: [],
            maxTestHistory: [TestFixtures.makeMaxTest()]
        )

        let data = try JSONEncoder().encode(exportData)
        let decoded = try JSONDecoder().decode(ExportedAppData.self, from: data)
        XCTAssertTrue(decoded.tb3_export)
        XCTAssertEqual(decoded.schemaVersion, CURRENT_SCHEMA_VERSION)
        XCTAssertEqual(decoded.maxTestHistory.count, 1)
    }

    // MARK: - ActiveSessionState Codable

    func testActiveSessionStateRoundTrip() throws {
        let session = ActiveSessionState(
            status: .inProgress,
            templateId: "operator",
            week: 2,
            session: 1,
            exercises: [
                ActiveSessionExercise(
                    liftName: "Squat",
                    targetWeight: 200,
                    plates: [PlateCount(weight: 45, count: 1), PlateCount(weight: 25, count: 1)],
                    repsPerSet: .single(5),
                    isBodyweight: false
                )
            ],
            sets: [
                SessionSet(exerciseIndex: 0, setNumber: 1, targetReps: 5, actualReps: 5, completed: true, completedAt: 1000),
                SessionSet(exerciseIndex: 0, setNumber: 2, targetReps: 5, actualReps: nil, completed: false, completedAt: nil),
            ],
            currentExerciseIndex: 0,
            timerState: TimerState(phase: .rest, startedAt: 1000, restDurationSeconds: 120),
            startedAt: "2024-01-15T10:00:00Z",
            exerciseStartTimes: [0: "2024-01-15T10:00:00Z"],
            weekPercentage: 80,
            minSets: 3,
            maxSets: 5
        )

        let data = try JSONEncoder().encode(session)
        let decoded = try JSONDecoder().decode(ActiveSessionState.self, from: data)
        XCTAssertEqual(session, decoded)
    }

    // MARK: - PlateCount

    func testPlateCountCodable() throws {
        let plate = PlateCount(weight: 45, count: 2)
        let data = try JSONEncoder().encode(plate)
        let decoded = try JSONDecoder().decode(PlateCount.self, from: data)
        XCTAssertEqual(plate, decoded)
    }

    // MARK: - PlateInventory

    func testPlateInventoryCodable() throws {
        let inventory = TestFixtures.makeInventory()
        let data = try JSONEncoder().encode(inventory)
        let decoded = try JSONDecoder().decode(PlateInventory.self, from: data)
        XCTAssertEqual(inventory, decoded)
    }

    func testDefaultInventories() {
        XCTAssertEqual(DEFAULT_PLATE_INVENTORY_BARBELL.plates.count, 7)
        XCTAssertEqual(DEFAULT_PLATE_INVENTORY_BELT.plates.count, 7)
        // Barbell has 4x45, belt has 2x45
        XCTAssertEqual(DEFAULT_PLATE_INVENTORY_BARBELL.plates[0].available, 4)
        XCTAssertEqual(DEFAULT_PLATE_INVENTORY_BELT.plates[0].available, 2)
    }
}
