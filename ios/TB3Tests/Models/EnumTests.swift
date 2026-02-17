// TB3 iOS Tests — Core Enums

import XCTest
@testable import TB3

final class EnumTests: XCTestCase {

    // MARK: - LiftName

    func testLiftNameCount() {
        XCTAssertEqual(LiftName.allCases.count, 5)
    }

    func testLiftNameRawValues() {
        XCTAssertEqual(LiftName.squat.rawValue, "Squat")
        XCTAssertEqual(LiftName.bench.rawValue, "Bench")
        XCTAssertEqual(LiftName.deadlift.rawValue, "Deadlift")
        XCTAssertEqual(LiftName.militaryPress.rawValue, "Military Press")
        XCTAssertEqual(LiftName.weightedPullUp.rawValue, "Weighted Pull-up")
    }

    func testLiftNameIsBodyweight() {
        XCTAssertTrue(LiftName.weightedPullUp.isBodyweight)
        XCTAssertFalse(LiftName.squat.isBodyweight)
        XCTAssertFalse(LiftName.bench.isBodyweight)
        XCTAssertFalse(LiftName.deadlift.isBodyweight)
        XCTAssertFalse(LiftName.militaryPress.isBodyweight)
    }

    func testLiftNameCodable() throws {
        let encoded = try JSONEncoder().encode(LiftName.squat)
        let decoded = try JSONDecoder().decode(LiftName.self, from: encoded)
        XCTAssertEqual(decoded, .squat)
    }

    // MARK: - TemplateId

    func testTemplateIdCount() {
        XCTAssertEqual(TemplateId.allCases.count, 7)
    }

    func testTemplateIdRawValues() {
        XCTAssertEqual(TemplateId.operator.rawValue, "operator")
        XCTAssertEqual(TemplateId.zulu.rawValue, "zulu")
        XCTAssertEqual(TemplateId.fighter.rawValue, "fighter")
        XCTAssertEqual(TemplateId.gladiator.rawValue, "gladiator")
        XCTAssertEqual(TemplateId.massProtocol.rawValue, "mass-protocol")
        XCTAssertEqual(TemplateId.massStrength.rawValue, "mass-strength")
        XCTAssertEqual(TemplateId.greyMan.rawValue, "grey-man")
    }

    func testTemplateIdCodable() throws {
        for template in TemplateId.allCases {
            let encoded = try JSONEncoder().encode(template)
            let decoded = try JSONDecoder().decode(TemplateId.self, from: encoded)
            XCTAssertEqual(decoded, template)
        }
    }

    // MARK: - TimerPhase

    func testTimerPhaseValues() {
        XCTAssertEqual(TimerPhase.rest.rawValue, "rest")
        XCTAssertEqual(TimerPhase.exercise.rawValue, "exercise")
    }

    func testTimerPhaseCodable() throws {
        let encoded = try JSONEncoder().encode(TimerPhase.rest)
        let decoded = try JSONDecoder().decode(TimerPhase.self, from: encoded)
        XCTAssertEqual(decoded, .rest)
    }

    // MARK: - WorkoutStatus

    func testWorkoutStatusRawValues() {
        XCTAssertEqual(WorkoutStatus.inProgress.rawValue, "in_progress")
        XCTAssertEqual(WorkoutStatus.paused.rawValue, "paused")
    }

    // MARK: - SoundMode

    func testSoundModeValues() {
        XCTAssertEqual(SoundMode.on.rawValue, "on")
        XCTAssertEqual(SoundMode.off.rawValue, "off")
        XCTAssertEqual(SoundMode.vibrate.rawValue, "vibrate")
    }

    // MARK: - Schema Version

    func testSchemaVersion() {
        XCTAssertGreaterThanOrEqual(CURRENT_SCHEMA_VERSION, 1)
        XCTAssertEqual(CURRENT_SCHEMA_VERSION, 3)
    }

    // MARK: - DerivedLiftEntry

    func testDerivedLiftEntryId() {
        let lift = TestFixtures.makeLift(name: "Squat", weight: 300, reps: 5)
        XCTAssertEqual(lift.id, "Squat")
    }

    func testDerivedLiftEntryEquality() {
        let a = TestFixtures.makeLift(name: "Squat", weight: 300, reps: 5)
        let b = TestFixtures.makeLift(name: "Squat", weight: 300, reps: 5)
        XCTAssertEqual(a, b)
    }

    func testDerivedLiftEntryInequality() {
        let a = TestFixtures.makeLift(name: "Squat", weight: 300, reps: 5)
        let b = TestFixtures.makeLift(name: "Squat", weight: 350, reps: 5)
        XCTAssertNotEqual(a, b)
    }
}
