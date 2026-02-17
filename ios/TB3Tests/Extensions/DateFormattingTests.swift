// TB3 iOS Tests — Date+Formatting extensions

import XCTest
@testable import TB3

final class DateFormattingTests: XCTestCase {

    // MARK: - ISO 8601

    func testISO8601Output() {
        let date = Date(timeIntervalSince1970: 0) // 1970-01-01T00:00:00Z
        XCTAssertTrue(date.iso8601.contains("1970"))
    }

    func testISO8601Now() {
        let now = Date.iso8601Now()
        XCTAssertFalse(now.isEmpty)
        XCTAssertTrue(now.contains("T"))
    }

    func testFromISO8601WithFractionalSeconds() {
        let dateStr = "2024-01-15T10:30:45.123Z"
        let date = Date.fromISO8601(dateStr)
        XCTAssertNotNil(date)
    }

    func testFromISO8601WithoutFractionalSeconds() {
        let dateStr = "2024-01-15T10:30:45Z"
        let date = Date.fromISO8601(dateStr)
        XCTAssertNotNil(date)
    }

    func testFromISO8601InvalidString() {
        let date = Date.fromISO8601("not a date")
        XCTAssertNil(date)
    }

    func testFromISO8601EmptyString() {
        let date = Date.fromISO8601("")
        XCTAssertNil(date)
    }

    func testFromISO8601RoundTrip() {
        let original = Date()
        let isoString = original.iso8601
        let parsed = Date.fromISO8601(isoString)
        XCTAssertNotNil(parsed)
        // Allow 1 second tolerance due to formatting precision
        XCTAssertEqual(original.timeIntervalSince1970, parsed!.timeIntervalSince1970, accuracy: 1.0)
    }

    // MARK: - String Extension

    func testStringAsDate() {
        let dateStr = "2024-01-15T10:30:45Z"
        XCTAssertNotNil(dateStr.asDate)
    }

    func testInvalidStringAsDate() {
        XCTAssertNil("garbage".asDate)
    }

    // MARK: - Display Formats

    func testShortDisplay() {
        let date = Date.fromISO8601("2024-01-15T10:30:45Z")!
        let display = date.shortDisplay
        XCTAssertFalse(display.isEmpty)
        XCTAssertTrue(display.contains("2024") || display.contains("15") || display.contains("Jan"))
    }

    func testFullDisplay() {
        let date = Date.fromISO8601("2024-01-15T10:30:45Z")!
        let display = date.fullDisplay
        XCTAssertFalse(display.isEmpty)
        // Full display includes time
        XCTAssertTrue(display.count > date.shortDisplay.count)
    }

    // MARK: - Generate ID

    func testGenerateIdFormat() {
        let id = generateId()
        XCTAssertFalse(id.isEmpty)
        // UUID format: lowercase, 36 chars with hyphens
        XCTAssertEqual(id.count, 36)
        XCTAssertEqual(id, id.lowercased())
    }

    func testGenerateIdUniqueness() {
        let ids = (0..<100).map { _ in generateId() }
        XCTAssertEqual(Set(ids).count, ids.count)
    }

    func testDateGenerateIdMatchesFreeFunction() {
        // Both should produce valid UUIDs
        let id1 = Date.generateId()
        let id2 = generateId()
        XCTAssertEqual(id1.count, 36)
        XCTAssertEqual(id2.count, 36)
        XCTAssertNotEqual(id1, id2)
    }
}
