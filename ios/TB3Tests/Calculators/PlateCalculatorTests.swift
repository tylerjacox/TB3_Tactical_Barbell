// TB3 iOS Tests — PlateCalculator (mirrors calculators/plates.test.ts)

import XCTest
@testable import TB3

final class PlateCalculatorTests: XCTestCase {

    let inventory = TestFixtures.makeInventory()
    let beltInventory = TestFixtures.makeBeltInventory()

    // MARK: - Barbell Plates

    func testBarOnly() {
        let result = PlateCalculator.calculateBarbellPlates(totalWeight: 45, barbellWeight: 45, inventory: inventory)
        XCTAssertTrue(result.achievable)
        XCTAssertTrue(result.isBarOnly)
        XCTAssertTrue(result.plates.isEmpty)
    }

    func testBelowBar() {
        let result = PlateCalculator.calculateBarbellPlates(totalWeight: 30, barbellWeight: 45, inventory: inventory)
        XCTAssertFalse(result.achievable)
        XCTAssertTrue(result.isBelowBar)
    }

    func testZeroWeight() {
        let result = PlateCalculator.calculateBarbellPlates(totalWeight: 0, barbellWeight: 45, inventory: inventory)
        XCTAssertFalse(result.achievable)
    }

    func testNegativeWeight() {
        let result = PlateCalculator.calculateBarbellPlates(totalWeight: -10, barbellWeight: 45, inventory: inventory)
        XCTAssertFalse(result.achievable)
    }

    func testSimplePlateLoad135() {
        // 135 = 45 bar + 45 per side
        let result = PlateCalculator.calculateBarbellPlates(totalWeight: 135, barbellWeight: 45, inventory: inventory)
        XCTAssertTrue(result.achievable)
        XCTAssertEqual(result.plates.count, 1)
        XCTAssertEqual(result.plates[0].weight, 45)
        XCTAssertEqual(result.plates[0].count, 1)
    }

    func testPlateLoad225() {
        // 225 = 45 bar + 90 per side = 2x45
        let result = PlateCalculator.calculateBarbellPlates(totalWeight: 225, barbellWeight: 45, inventory: inventory)
        XCTAssertTrue(result.achievable)
        XCTAssertEqual(result.plates.count, 1)
        XCTAssertEqual(result.plates[0].weight, 45)
        XCTAssertEqual(result.plates[0].count, 2)
    }

    func testPlateLoad315() {
        // 315 = 45 bar + 135 per side = 3x45
        let result = PlateCalculator.calculateBarbellPlates(totalWeight: 315, barbellWeight: 45, inventory: inventory)
        XCTAssertTrue(result.achievable)
        XCTAssertEqual(result.plates.count, 1)
        XCTAssertEqual(result.plates[0].weight, 45)
        XCTAssertEqual(result.plates[0].count, 3)
    }

    func testMixedPlates() {
        // 190 = 45 bar + 72.5 per side = 45 + 25 + 2.5
        let result = PlateCalculator.calculateBarbellPlates(totalWeight: 190, barbellWeight: 45, inventory: inventory)
        XCTAssertTrue(result.achievable)
        XCTAssertTrue(result.plates.count >= 2)
    }

    func testNotAchievable() {
        let smallInventory = TestFixtures.makeInventory(plates: [(45, 1)])
        // 200 = 45 bar + 77.5 per side — can only do 45 per side = 135 total
        let result = PlateCalculator.calculateBarbellPlates(totalWeight: 200, barbellWeight: 45, inventory: smallInventory)
        XCTAssertFalse(result.achievable)
        XCTAssertNotNil(result.nearestAchievable)
    }

    func testExceedsInventory() {
        // 4x45 per side max = 360 + 45 bar = 405
        // Try 500 = 45 bar + 227.5 per side (5x45 + more, but only 4x45)
        let result = PlateCalculator.calculateBarbellPlates(totalWeight: 500, barbellWeight: 45, inventory: inventory)
        // May or may not be achievable depending on mix — just verify no crash
        XCTAssertNotNil(result.displayText)
    }

    // MARK: - Belt Plates

    func testBodyweightOnly() {
        let result = PlateCalculator.calculateBeltPlates(totalWeight: 0, inventory: beltInventory)
        XCTAssertTrue(result.achievable)
        XCTAssertTrue(result.isBodyweightOnly)
    }

    func testNegativeBeltWeight() {
        let result = PlateCalculator.calculateBeltPlates(totalWeight: -5, inventory: beltInventory)
        XCTAssertTrue(result.achievable)
        XCTAssertTrue(result.isBodyweightOnly)
    }

    func testBeltSimple45() {
        let result = PlateCalculator.calculateBeltPlates(totalWeight: 45, inventory: beltInventory)
        XCTAssertTrue(result.achievable)
        XCTAssertEqual(result.plates.count, 1)
        XCTAssertEqual(result.plates[0].weight, 45)
        XCTAssertEqual(result.plates[0].count, 1)
    }

    func testBeltMixed() {
        let result = PlateCalculator.calculateBeltPlates(totalWeight: 52.5, inventory: beltInventory)
        XCTAssertTrue(result.achievable)
        // 45 + 5 + 2.5 = 52.5
    }

    func testBeltDisplayText() {
        let result = PlateCalculator.calculateBeltPlates(totalWeight: 45, inventory: beltInventory)
        XCTAssertTrue(result.displayText.contains("on belt"))
    }
}
