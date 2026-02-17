// TB3 iOS Tests — ValidationService (runtime + import validation)

import XCTest
@testable import TB3

final class ValidationServiceTests: XCTestCase {

    // MARK: - Runtime Validation

    func testValidDataReturnsOk() {
        let result = ValidationService.validateAppData(
            profile: TestFixtures.makeProfile(),
            activeProgram: TestFixtures.makeProgram(),
            sessionHistory: [],
            maxTestHistory: [TestFixtures.makeMaxTest()]
        )
        XCTAssertEqual(result.severity, .ok)
        XCTAssertTrue(result.errors.isEmpty)
    }

    func testUnknownTemplateIsRecoverable() {
        let program = SyncActiveProgram(
            templateId: "nonexistent",
            startDate: "2024-01-01",
            currentWeek: 1,
            currentSession: 1,
            liftSelections: [:],
            lastModified: "2024-01-01T00:00:00Z"
        )
        let result = ValidationService.validateAppData(
            profile: TestFixtures.makeProfile(),
            activeProgram: program,
            sessionHistory: [],
            maxTestHistory: []
        )
        XCTAssertEqual(result.severity, .recoverable)
        XCTAssertTrue(result.errors.contains { $0.contains("Unknown template") })
    }

    func testUnknownLiftIsWarning() {
        let test = SyncOneRepMaxTest(
            id: generateId(), date: "2024-01-01", liftName: "Bicep Curl",
            weight: 50, reps: 10, calculatedMax: 66.7, maxType: "training",
            workingMax: 66.7, lastModified: "2024-01-01"
        )
        let result = ValidationService.validateAppData(
            profile: TestFixtures.makeProfile(),
            activeProgram: nil,
            sessionHistory: [],
            maxTestHistory: [test]
        )
        XCTAssertEqual(result.severity, .warning)
        XCTAssertTrue(result.errors.contains { $0.contains("Unknown lift") })
    }

    func testWeightOutOfRangeIsWarning() {
        let test = SyncOneRepMaxTest(
            id: generateId(), date: "2024-01-01", liftName: "Squat",
            weight: 2000, reps: 5, calculatedMax: 2333, maxType: "training",
            workingMax: 2333, lastModified: "2024-01-01"
        )
        let result = ValidationService.validateAppData(
            profile: TestFixtures.makeProfile(),
            activeProgram: nil,
            sessionHistory: [],
            maxTestHistory: [test]
        )
        XCTAssertEqual(result.severity, .warning)
        XCTAssertTrue(result.errors.contains { $0.contains("Weight out of range") })
    }

    func testRepsOutOfRangeIsWarning() {
        let test = SyncOneRepMaxTest(
            id: generateId(), date: "2024-01-01", liftName: "Squat",
            weight: 200, reps: 20, calculatedMax: 333, maxType: "training",
            workingMax: 333, lastModified: "2024-01-01"
        )
        let result = ValidationService.validateAppData(
            profile: TestFixtures.makeProfile(),
            activeProgram: nil,
            sessionHistory: [],
            maxTestHistory: [test]
        )
        XCTAssertEqual(result.severity, .warning)
        XCTAssertTrue(result.errors.contains { $0.contains("Reps out of range") })
    }

    func testDuplicateSessionIds() {
        let log = SyncSessionLog(
            id: "dup-id",
            date: "2024-01-01", templateId: "operator", week: 1, sessionNumber: 1,
            status: "completed", startedAt: "2024-01-01T10:00:00Z",
            completedAt: "2024-01-01T11:00:00Z", exercises: [], notes: "",
            durationSeconds: nil, lastModified: "2024-01-01T11:00:00Z"
        )
        let result = ValidationService.validateAppData(
            profile: TestFixtures.makeProfile(),
            activeProgram: nil,
            sessionHistory: [log, log],
            maxTestHistory: []
        )
        XCTAssertEqual(result.severity, .warning)
        XCTAssertTrue(result.errors.contains { $0.contains("Duplicate session ID") })
    }

    func testDuplicateMaxTestIds() {
        let test = SyncOneRepMaxTest(
            id: "dup-test-id", date: "2024-01-01", liftName: "Squat",
            weight: 300, reps: 5, calculatedMax: 350, maxType: "training",
            workingMax: 350, lastModified: "2024-01-01"
        )
        let result = ValidationService.validateAppData(
            profile: TestFixtures.makeProfile(),
            activeProgram: nil,
            sessionHistory: [],
            maxTestHistory: [test, test]
        )
        XCTAssertEqual(result.severity, .warning)
        XCTAssertTrue(result.errors.contains { $0.contains("Duplicate max test ID") })
    }

    // MARK: - Import Validation

    func testImportFileTooLarge() {
        let largeData = Data(repeating: 0, count: 2_000_000)
        let result = ValidationService.validateImportData(largeData)
        switch result {
        case .failure(let error):
            XCTAssertTrue(error.message.contains("too large"))
        case .success:
            XCTFail("Should reject oversized files")
        }
    }

    func testImportInvalidJSON() {
        let data = "not json".data(using: .utf8)!
        let result = ValidationService.validateImportData(data)
        switch result {
        case .failure(let error):
            XCTAssertTrue(error.message.contains("parse JSON"))
        case .success:
            XCTFail("Should reject invalid JSON")
        }
    }

    func testImportMissingSentinel() {
        let json: [String: Any] = ["schemaVersion": 3]
        let data = try! JSONSerialization.data(withJSONObject: json)
        let result = ValidationService.validateImportData(data)
        switch result {
        case .failure(let error):
            XCTAssertTrue(error.message.contains("TB3 backup"))
        case .success:
            XCTFail("Should reject missing sentinel")
        }
    }

    func testImportFutureSchemaVersion() {
        let json: [String: Any] = [
            "tb3_export": true,
            "schemaVersion": 999
        ]
        let data = try! JSONSerialization.data(withJSONObject: json)
        let result = ValidationService.validateImportData(data)
        switch result {
        case .failure(let error):
            XCTAssertTrue(error.message.contains("newer version"))
        case .success:
            XCTFail("Should reject future schema")
        }
    }

    func testImportPrototypePollution() {
        let json: [String: Any] = [
            "tb3_export": true,
            "schemaVersion": CURRENT_SCHEMA_VERSION,
            "__proto__": ["malicious": true]
        ]
        let data = try! JSONSerialization.data(withJSONObject: json)
        let result = ValidationService.validateImportData(data)
        switch result {
        case .failure(let error):
            XCTAssertTrue(error.message.contains("unsafe keys"))
        case .success:
            XCTFail("Should reject prototype pollution")
        }
    }

    func testImportWeightOutOfRange() throws {
        let exportData = ExportedAppData(
            tb3_export: true,
            exportedAt: Date.iso8601Now(),
            appVersion: "1.0.0",
            schemaVersion: CURRENT_SCHEMA_VERSION,
            profile: TestFixtures.makeProfile(),
            activeProgram: nil,
            sessionHistory: [],
            maxTestHistory: [
                SyncOneRepMaxTest(
                    id: generateId(), date: "2024-01-01", liftName: "Squat",
                    weight: 2000, reps: 5, calculatedMax: 2333, maxType: "training",
                    workingMax: 2333, lastModified: "2024-01-01"
                )
            ]
        )
        let data = try JSONEncoder().encode(exportData)
        let result = ValidationService.validateImportData(data)
        switch result {
        case .failure(let error):
            XCTAssertTrue(error.message.contains("Weight out of range"))
        case .success:
            XCTFail("Should reject weight out of range")
        }
    }

    func testImportDuplicateSessionIds() throws {
        let log = SyncSessionLog(
            id: "dup-id",
            date: "2024-01-01", templateId: "operator", week: 1, sessionNumber: 1,
            status: "completed", startedAt: "2024-01-01T10:00:00Z",
            completedAt: "2024-01-01T11:00:00Z", exercises: [], notes: "",
            durationSeconds: nil, lastModified: "2024-01-01T11:00:00Z"
        )
        let exportData = ExportedAppData(
            tb3_export: true,
            exportedAt: Date.iso8601Now(),
            appVersion: "1.0.0",
            schemaVersion: CURRENT_SCHEMA_VERSION,
            profile: TestFixtures.makeProfile(),
            activeProgram: nil,
            sessionHistory: [log, log],
            maxTestHistory: []
        )
        let data = try JSONEncoder().encode(exportData)
        let result = ValidationService.validateImportData(data)
        switch result {
        case .failure(let error):
            XCTAssertTrue(error.message.contains("Duplicate session ID"))
        case .success:
            XCTFail("Should reject duplicate IDs")
        }
    }
}
