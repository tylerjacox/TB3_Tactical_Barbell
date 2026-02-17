// TB3 iOS Tests — Schedule Generator (mirrors templates/schedule.test.ts)

import XCTest
@testable import TB3

final class ScheduleGeneratorTests: XCTestCase {

    let profile = TestFixtures.makeProfile()
    let lifts = TestFixtures.standardLifts

    // MARK: - Operator Template

    func testOperatorScheduleStructure() {
        let program = TestFixtures.makeProgram(templateId: "operator")
        let schedule = ScheduleGenerator.generateSchedule(program: program, lifts: lifts, profile: profile)

        XCTAssertEqual(schedule.weeks.count, 6)
        for week in schedule.weeks {
            XCTAssertEqual(week.sessions.count, 3)
        }
    }

    func testOperatorWeek1Session1Exercises() {
        let program = TestFixtures.makeProgram(templateId: "operator")
        let schedule = ScheduleGenerator.generateSchedule(program: program, lifts: lifts, profile: profile)

        let session = schedule.weeks[0].sessions[0]
        XCTAssertEqual(session.exercises.count, 3)
        XCTAssertEqual(session.exercises[0].liftName, "Squat")
        XCTAssertEqual(session.exercises[1].liftName, "Bench")
        XCTAssertEqual(session.exercises[2].liftName, "Weighted Pull-up")
    }

    func testOperatorSession3HasDeadlift() {
        let program = TestFixtures.makeProgram(templateId: "operator")
        let schedule = ScheduleGenerator.generateSchedule(program: program, lifts: lifts, profile: profile)

        let session = schedule.weeks[0].sessions[2]
        XCTAssertEqual(session.exercises[2].liftName, "Deadlift")
    }

    func testOperatorTargetWeightsArePositive() {
        let program = TestFixtures.makeProgram(templateId: "operator")
        let schedule = ScheduleGenerator.generateSchedule(program: program, lifts: lifts, profile: profile)

        for week in schedule.weeks {
            for session in week.sessions {
                for exercise in session.exercises {
                    XCTAssertGreaterThan(exercise.targetWeight, 0, "\(exercise.liftName) has zero weight")
                }
            }
        }
    }

    func testOperatorWeightsIncreaseByPercentage() {
        let program = TestFixtures.makeProgram(templateId: "operator")
        let schedule = ScheduleGenerator.generateSchedule(program: program, lifts: lifts, profile: profile)

        let week1Weight = schedule.weeks[0].sessions[0].exercises[0].targetWeight // 70%
        let week2Weight = schedule.weeks[1].sessions[0].exercises[0].targetWeight // 80%
        XCTAssertGreaterThan(week2Weight, week1Weight)
    }

    // MARK: - Zulu Template

    func testZuluScheduleStructure() {
        let program = TestFixtures.makeProgram(templateId: "zulu", liftSelections: [
            "A": ["Military Press", "Squat", "Weighted Pull-up"],
            "B": ["Bench", "Deadlift"],
        ])
        let schedule = ScheduleGenerator.generateSchedule(program: program, lifts: lifts, profile: profile)

        XCTAssertEqual(schedule.weeks.count, 6)
        for week in schedule.weeks {
            XCTAssertEqual(week.sessions.count, 4)
        }
    }

    func testZuluABSplit() {
        let program = TestFixtures.makeProgram(templateId: "zulu", liftSelections: [
            "A": ["Military Press", "Squat"],
            "B": ["Bench", "Deadlift"],
        ])
        let schedule = ScheduleGenerator.generateSchedule(program: program, lifts: lifts, profile: profile)

        // Sessions 1,3 = A lifts; Sessions 2,4 = B lifts
        let week1 = schedule.weeks[0]
        XCTAssertEqual(week1.sessions[0].exercises.map { $0.liftName }, ["Military Press", "Squat"])
        XCTAssertEqual(week1.sessions[1].exercises.map { $0.liftName }, ["Bench", "Deadlift"])
        XCTAssertEqual(week1.sessions[2].exercises.map { $0.liftName }, ["Military Press", "Squat"])
        XCTAssertEqual(week1.sessions[3].exercises.map { $0.liftName }, ["Bench", "Deadlift"])
    }

    // MARK: - Fighter Template

    func testFighterScheduleStructure() {
        let program = TestFixtures.makeProgram(templateId: "fighter", liftSelections: [
            "cluster": ["Squat", "Bench"],
        ])
        let schedule = ScheduleGenerator.generateSchedule(program: program, lifts: lifts, profile: profile)

        XCTAssertEqual(schedule.weeks.count, 6)
        for week in schedule.weeks {
            XCTAssertEqual(week.sessions.count, 2)
        }
    }

    // MARK: - Gladiator Template

    func testGladiatorScheduleStructure() {
        let program = TestFixtures.makeProgram(templateId: "gladiator", liftSelections: [
            "cluster": ["Squat", "Bench", "Deadlift"],
        ])
        let schedule = ScheduleGenerator.generateSchedule(program: program, lifts: lifts, profile: profile)

        XCTAssertEqual(schedule.weeks.count, 6)
        for week in schedule.weeks {
            XCTAssertEqual(week.sessions.count, 3)
            for session in week.sessions {
                XCTAssertEqual(session.exercises.count, 3)
            }
        }
    }

    // MARK: - Mass Strength Template

    func testMassStrengthDeadliftDay() {
        let program = TestFixtures.makeProgram(templateId: "mass-strength")
        let schedule = ScheduleGenerator.generateSchedule(program: program, lifts: lifts, profile: profile)

        XCTAssertEqual(schedule.weeks.count, 3)
        // Session 4 = Deadlift only
        for week in schedule.weeks {
            XCTAssertEqual(week.sessions[3].exercises.count, 1)
            XCTAssertEqual(week.sessions[3].exercises[0].liftName, "Deadlift")
        }
    }

    // MARK: - Grey Man Template

    func testGreyManScheduleStructure() {
        let program = TestFixtures.makeProgram(templateId: "grey-man", liftSelections: [
            "cluster": ["Squat", "Bench", "Deadlift"],
        ])
        let schedule = ScheduleGenerator.generateSchedule(program: program, lifts: lifts, profile: profile)

        XCTAssertEqual(schedule.weeks.count, 12)
    }

    // MARK: - Missing Lift

    func testMissingLiftShowsZeroWeight() {
        let partialLifts = [TestFixtures.makeLift(name: "Squat")]
        let program = TestFixtures.makeProgram(templateId: "operator")
        let schedule = ScheduleGenerator.generateSchedule(program: program, lifts: partialLifts, profile: profile)

        let session = schedule.weeks[0].sessions[0]
        // Squat should have weight, Bench and Pull-up should be 0
        XCTAssertGreaterThan(session.exercises[0].targetWeight, 0) // Squat
        XCTAssertEqual(session.exercises[1].targetWeight, 0)       // Bench (missing)
    }

    // MARK: - Source Hash

    func testSourceHashDeterministic() {
        let program = TestFixtures.makeProgram(templateId: "operator")
        let hash1 = ScheduleGenerator.computeSourceHash(program: program, lifts: lifts, profile: profile)
        let hash2 = ScheduleGenerator.computeSourceHash(program: program, lifts: lifts, profile: profile)
        XCTAssertEqual(hash1, hash2)
    }

    func testSourceHashChangesWithLifts() {
        let program = TestFixtures.makeProgram(templateId: "operator")
        let hash1 = ScheduleGenerator.computeSourceHash(program: program, lifts: lifts, profile: profile)

        var modifiedLifts = lifts
        modifiedLifts[0] = TestFixtures.makeLift(name: "Squat", weight: 350, reps: 5)
        let hash2 = ScheduleGenerator.computeSourceHash(program: program, lifts: modifiedLifts, profile: profile)
        XCTAssertNotEqual(hash1, hash2)
    }

    // MARK: - Unknown Template

    func testUnknownTemplateReturnsEmpty() {
        let program = SyncActiveProgram(
            templateId: "nonexistent",
            startDate: "2024-01-01",
            currentWeek: 1,
            currentSession: 1,
            liftSelections: [:],
            lastModified: "2024-01-01T00:00:00Z"
        )
        let schedule = ScheduleGenerator.generateSchedule(program: program, lifts: lifts, profile: profile)
        XCTAssertTrue(schedule.weeks.isEmpty)
    }

    // MARK: - Plate Achievability

    func testExercisesHavePlateBreakdown() {
        let program = TestFixtures.makeProgram(templateId: "operator")
        let schedule = ScheduleGenerator.generateSchedule(program: program, lifts: lifts, profile: profile)

        let exercise = schedule.weeks[0].sessions[0].exercises[0] // Squat
        XCTAssertFalse(exercise.plateBreakdown.isEmpty)
        XCTAssertTrue(exercise.achievable)
    }
}
