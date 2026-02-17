// TB3 iOS Tests — OneRepMaxCalculator (mirrors calculators/oneRepMax.test.ts)

import XCTest
@testable import TB3

final class OneRepMaxCalculatorTests: XCTestCase {

    // MARK: - calculateOneRepMax

    func testOneRepMaxWithZeroWeight() {
        XCTAssertEqual(OneRepMaxCalculator.calculateOneRepMax(weight: 0, reps: 5), 0)
    }

    func testOneRepMaxWithZeroReps() {
        XCTAssertEqual(OneRepMaxCalculator.calculateOneRepMax(weight: 200, reps: 0), 0)
    }

    func testOneRepMaxWithNegativeWeight() {
        XCTAssertEqual(OneRepMaxCalculator.calculateOneRepMax(weight: -100, reps: 5), 0)
    }

    func testOneRepMaxWithNegativeReps() {
        XCTAssertEqual(OneRepMaxCalculator.calculateOneRepMax(weight: 200, reps: -1), 0)
    }

    func testOneRepMaxWithOneRep() {
        XCTAssertEqual(OneRepMaxCalculator.calculateOneRepMax(weight: 300, reps: 1), 300)
    }

    func testOneRepMaxEpleyFormula() {
        // 200 * (1 + 5/30) = 200 * 1.1667 = 233.33...
        let result = OneRepMaxCalculator.calculateOneRepMax(weight: 200, reps: 5)
        XCTAssertEqual(result, 200 * (1 + 5.0/30.0), accuracy: 0.01)
    }

    func testOneRepMaxWith10Reps() {
        // 150 * (1 + 10/30) = 150 * 1.333 = 200
        let result = OneRepMaxCalculator.calculateOneRepMax(weight: 150, reps: 10)
        XCTAssertEqual(result, 200, accuracy: 0.01)
    }

    // MARK: - calculateTrainingMax

    func testTrainingMax() {
        XCTAssertEqual(OneRepMaxCalculator.calculateTrainingMax(oneRepMax: 300), 270, accuracy: 0.01)
    }

    func testTrainingMaxZero() {
        XCTAssertEqual(OneRepMaxCalculator.calculateTrainingMax(oneRepMax: 0), 0)
    }

    // MARK: - roundWeight

    func testRoundWeightTo2_5() {
        XCTAssertEqual(OneRepMaxCalculator.roundWeight(201.3, increment: 2.5), 200)
        XCTAssertEqual(OneRepMaxCalculator.roundWeight(201.5, increment: 2.5), 202.5)
        XCTAssertEqual(OneRepMaxCalculator.roundWeight(203.75, increment: 2.5), 205)
    }

    func testRoundWeightTo5() {
        XCTAssertEqual(OneRepMaxCalculator.roundWeight(202, increment: 5), 200)
        XCTAssertEqual(OneRepMaxCalculator.roundWeight(203, increment: 5), 205)
        XCTAssertEqual(OneRepMaxCalculator.roundWeight(207.5, increment: 5), 210)
    }

    // MARK: - calculatePercentageWeight

    func testPercentageWeight70() {
        // workingMax 270, 70% = 189, rounded to 2.5 = 190
        let result = OneRepMaxCalculator.calculatePercentageWeight(workingMax: 270, percentage: 70, roundingIncrement: 2.5)
        XCTAssertEqual(result, 190)
    }

    func testPercentageWeight90() {
        // workingMax 270, 90% = 243, rounded to 2.5 = 242.5
        let result = OneRepMaxCalculator.calculatePercentageWeight(workingMax: 270, percentage: 90, roundingIncrement: 2.5)
        XCTAssertEqual(result, 242.5)
    }

    func testPercentageWeight100() {
        // workingMax 270, 100% = 270, rounded to 5 = 270
        let result = OneRepMaxCalculator.calculatePercentageWeight(workingMax: 270, percentage: 100, roundingIncrement: 5)
        XCTAssertEqual(result, 270)
    }

    // MARK: - calculatePercentageTable

    func testPercentageTable() {
        let table = OneRepMaxCalculator.calculatePercentageTable(workingMax: 270, roundingIncrement: 2.5)
        XCTAssertEqual(table.count, 8)
        XCTAssertEqual(table[0].percentage, 65)
        XCTAssertEqual(table[7].percentage, 100)
        // 65% of 270 = 175.5, rounded to 2.5 = 175
        XCTAssertEqual(table[0].weight, 175)
        // 100% of 270 = 270
        XCTAssertEqual(table[7].weight, 270)
    }
}
