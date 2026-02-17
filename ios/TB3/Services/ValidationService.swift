// TB3 iOS — Validation Service (mirrors services/validation.ts)

import Foundation

enum ValidationSeverity: String {
    case ok
    case warning
    case recoverable
    case fatal
}

struct ValidationResult {
    var severity: ValidationSeverity
    var errors: [String]

    static let ok = ValidationResult(severity: .ok, errors: [])
}

struct ImportError: Error, LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

struct ValidationService {
    private static let knownTemplates = Set(TemplateId.allCases.map(\.rawValue))
    private static let knownLifts = Set(LiftName.allCases.map(\.rawValue))

    // MARK: - Runtime Validation

    static func validateAppData(
        profile: SyncProfile,
        activeProgram: SyncActiveProgram?,
        sessionHistory: [SyncSessionLog],
        maxTestHistory: [SyncOneRepMaxTest]
    ) -> ValidationResult {
        var errors: [String] = []
        var severity: ValidationSeverity = .ok

        // Template reference check
        if let program = activeProgram, !knownTemplates.contains(program.templateId) {
            errors.append("Unknown template: \(program.templateId)")
            severity = .recoverable
        }

        // Lift names
        for test in maxTestHistory {
            if !knownLifts.contains(test.liftName) {
                errors.append("Unknown lift: \(test.liftName)")
                if severity == .ok { severity = .warning }
            }
        }

        // Weight range
        for test in maxTestHistory {
            if test.weight < 1 || test.weight > 1500 {
                errors.append("Weight out of range: \(test.weight)")
                if severity == .ok { severity = .warning }
            }
            if test.reps < 1 || test.reps > 15 {
                errors.append("Reps out of range: \(test.reps)")
                if severity == .ok { severity = .warning }
            }
        }

        // Session ID uniqueness
        let sessionIds = sessionHistory.map(\.id)
        if Set(sessionIds).count != sessionIds.count {
            errors.append("Duplicate session ID found")
            if severity == .ok { severity = .warning }
        }

        // Max test ID uniqueness
        let testIds = maxTestHistory.map(\.id)
        if Set(testIds).count != testIds.count {
            errors.append("Duplicate max test ID found")
            if severity == .ok { severity = .warning }
        }

        return ValidationResult(severity: severity, errors: errors)
    }

    // MARK: - Import Validation (12-step)

    static func validateImportData(_ data: Data) -> Result<ExportedAppData, ImportError> {
        // Step 1: File size ≤ 1MB
        guard data.count <= 1_048_576 else {
            return .failure(ImportError(message: "File too large. Maximum size is 1MB."))
        }

        // Step 2: Valid JSON
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return .failure(ImportError(message: "Invalid file format. Could not parse JSON."))
        }

        // Step 3: Sentinel check
        guard json["tb3_export"] as? Bool == true else {
            return .failure(ImportError(message: "This file does not appear to be a TB3 backup."))
        }

        // Step 4: Schema version numeric
        guard let schemaVersion = json["schemaVersion"] as? Int else {
            return .failure(ImportError(message: "Unrecognized backup version."))
        }

        // Step 5: Schema version not from future
        guard schemaVersion <= CURRENT_SCHEMA_VERSION else {
            return .failure(ImportError(message: "This backup is from a newer version of TB3. Please update the app first."))
        }

        // Step 6: Prototype pollution defense
        let unsafeKeys = Set(["__proto__", "constructor", "prototype"])
        func hasUnsafeKeys(_ dict: [String: Any]) -> Bool {
            for key in dict.keys {
                if unsafeKeys.contains(key) { return true }
                if let nested = dict[key] as? [String: Any], hasUnsafeKeys(nested) { return true }
            }
            return false
        }
        if hasUnsafeKeys(json) {
            return .failure(ImportError(message: "Invalid file: contains unsafe keys."))
        }

        // Step 7: Apply migrations
        var migratedData = data
        if schemaVersion < CURRENT_SCHEMA_VERSION {
            switch MigrationService.migrate(data: data, fromVersion: schemaVersion) {
            case .success(let migrated):
                migratedData = migrated
            case .failure(let error):
                return .failure(ImportError(message: "Migration failed: \(error)"))
            }
        }

        // Step 8: Decode and validate required fields
        guard let decoded = try? JSONDecoder().decode(ExportedAppData.self, from: migratedData) else {
            return .failure(ImportError(message: "Missing or invalid required fields."))
        }

        // Step 9: Weight/Reps range checks
        for test in decoded.maxTestHistory {
            if test.weight < 1 || test.weight > 1500 {
                return .failure(ImportError(message: "Weight out of range: \(test.weight). Must be 1-1500."))
            }
            if test.reps < 1 || test.reps > 15 {
                return .failure(ImportError(message: "Reps out of range: \(test.reps). Must be 1-15."))
            }
        }

        // Step 10: Session notes length (if sessions have notes in future)
        // Currently no notes field, but keeping placeholder for compatibility

        // Step 11: ID uniqueness
        let sessionIds = decoded.sessionHistory.map(\.id)
        if Set(sessionIds).count != sessionIds.count {
            return .failure(ImportError(message: "Duplicate session ID found."))
        }
        let testIds = decoded.maxTestHistory.map(\.id)
        if Set(testIds).count != testIds.count {
            return .failure(ImportError(message: "Duplicate max test ID found."))
        }

        return .success(decoded)
    }
}
