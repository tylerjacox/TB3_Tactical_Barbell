// TB3 iOS Tests — Template Definitions (mirrors templates/definitions.test.ts)

import XCTest
@testable import TB3

final class TemplateDefinitionTests: XCTestCase {

    func testAllTemplatesCount() {
        XCTAssertEqual(Templates.all.count, 7)
    }

    func testAllTemplatesHaveUniqueIds() {
        let ids = Templates.all.map { $0.id }
        XCTAssertEqual(Set(ids).count, ids.count)
    }

    func testAllTemplatesHaveWeeks() {
        for template in Templates.all {
            XCTAssertFalse(template.weeks.isEmpty, "\(template.name) has no weeks")
            XCTAssertEqual(template.weeks.count, template.durationWeeks, "\(template.name) weeks mismatch")
        }
    }

    func testAllTemplatesHaveSessionDefs() {
        for template in Templates.all {
            XCTAssertFalse(template.sessionDefs.isEmpty, "\(template.name) has no session defs")
        }
    }

    func testWeekNumbersAreSequential() {
        for template in Templates.all {
            for (i, week) in template.weeks.enumerated() {
                XCTAssertEqual(week.weekNumber, i + 1, "\(template.name) week \(i) has wrong number")
            }
        }
    }

    func testSessionNumbersAreSequential() {
        for template in Templates.all {
            for (i, session) in template.sessionDefs.enumerated() {
                XCTAssertEqual(session.sessionNumber, i + 1, "\(template.name) session \(i) has wrong number")
            }
        }
    }

    func testSessionsPerWeekMatchesDefs() {
        for template in Templates.all {
            XCTAssertEqual(template.sessionsPerWeek, template.sessionDefs.count,
                           "\(template.name) sessionsPerWeek doesn't match sessionDefs count")
        }
    }

    // MARK: - Individual Template Tests

    func testOperator() {
        let t = Templates.operator
        XCTAssertEqual(t.id, .operator)
        XCTAssertEqual(t.durationWeeks, 6)
        XCTAssertEqual(t.sessionsPerWeek, 3)
        XCTAssertFalse(t.requiresLiftSelection)
        XCTAssertTrue(t.hasSetRange)
        XCTAssertEqual(t.sessionDefs[0].lifts, ["Squat", "Bench", "Weighted Pull-up"])
        XCTAssertEqual(t.sessionDefs[2].lifts, ["Squat", "Bench", "Deadlift"])
    }

    func testZulu() {
        let t = Templates.zulu
        XCTAssertEqual(t.id, .zulu)
        XCTAssertEqual(t.sessionsPerWeek, 4)
        XCTAssertTrue(t.requiresLiftSelection)
        XCTAssertNotNil(t.liftSlots)
        XCTAssertEqual(t.liftSlots?.count, 2)
        XCTAssertEqual(t.sessionDefs[0].liftSource, .a)
        XCTAssertEqual(t.sessionDefs[1].liftSource, .b)
    }

    func testFighter() {
        let t = Templates.fighter
        XCTAssertEqual(t.id, .fighter)
        XCTAssertEqual(t.sessionsPerWeek, 2)
        XCTAssertTrue(t.requiresLiftSelection)
        XCTAssertTrue(t.hasSetRange)
    }

    func testGladiator() {
        let t = Templates.gladiator
        XCTAssertEqual(t.id, .gladiator)
        XCTAssertEqual(t.sessionsPerWeek, 3)
        // Week 6 has descending reps [3,2,1,3,2]
        let week6 = t.weeks[5]
        XCTAssertEqual(week6.repsPerSet, .array([3, 2, 1, 3, 2]))
    }

    func testMassProtocol() {
        let t = Templates.massProtocol
        XCTAssertEqual(t.id, .massProtocol)
        XCTAssertTrue(t.hideRestTimer)
    }

    func testMassStrength() {
        let t = Templates.massStrength
        XCTAssertEqual(t.id, .massStrength)
        XCTAssertEqual(t.durationWeeks, 3)
        XCTAssertEqual(t.sessionsPerWeek, 4)
        XCTAssertFalse(t.requiresLiftSelection)
        XCTAssertEqual(t.sessionDefs[3].lifts, ["Deadlift"])
    }

    func testGreyMan() {
        let t = Templates.greyMan
        XCTAssertEqual(t.id, .greyMan)
        XCTAssertEqual(t.durationWeeks, 12)
    }

    // MARK: - Template Lookup

    func testGetTemplateById() {
        for template in Templates.all {
            XCTAssertNotNil(Templates.get(id: template.id))
        }
    }

    func testGetTemplatesForDays() {
        XCTAssertEqual(Templates.getForDays(2).count, 1) // Fighter only
        XCTAssertEqual(Templates.getForDays(2).first?.id, .fighter)
        XCTAssertEqual(Templates.getForDays(4).count, 1) // Zulu only
        XCTAssertEqual(Templates.getForDays(4).first?.id, .zulu)
        XCTAssertEqual(Templates.getForDays(3).count, 4) // Operator, Gladiator, Mass Protocol, Grey Man
    }

    // MARK: - Zulu Cluster Percentages

    func testZuluClusterPercentages() {
        XCTAssertEqual(Templates.zuluClusterPercentages.count, 6)
        XCTAssertEqual(Templates.zuluClusterPercentages[1]?.clusterOne, 70)
        XCTAssertEqual(Templates.zuluClusterPercentages[1]?.clusterTwo, 75)
    }

    // MARK: - Mass Strength DL Overrides

    func testMassStrengthDLWeeks() {
        XCTAssertEqual(Templates.massStrengthDLWeeks.count, 3)
        XCTAssertEqual(Templates.massStrengthDLWeeks[1]?.sets, 4)
        XCTAssertEqual(Templates.massStrengthDLWeeks[1]?.reps, 5)
        XCTAssertEqual(Templates.massStrengthDLWeeks[3]?.sets, 1)
        XCTAssertEqual(Templates.massStrengthDLWeeks[3]?.reps, 3)
    }
}
