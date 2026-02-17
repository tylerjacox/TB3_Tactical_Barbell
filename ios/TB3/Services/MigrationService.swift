// TB3 iOS — Migration Service (mirrors services/migrations.ts)
// Handles schema v1 → v2 → v3 migrations for imported data.

import Foundation

struct MigrationService {
    /// Migrate exported JSON data from `fromVersion` to CURRENT_SCHEMA_VERSION.
    static func migrate(data: Data, fromVersion: Int) -> Result<Data, ImportError> {
        guard var json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return .failure(ImportError(message: "Could not parse JSON for migration."))
        }

        var version = fromVersion

        while version < CURRENT_SCHEMA_VERSION {
            switch version {
            case 1:
                // v1 → v2: Add voiceAnnouncements
                if var profile = json["profile"] as? [String: Any] {
                    if profile["voiceAnnouncements"] == nil {
                        profile["voiceAnnouncements"] = false
                    }
                    json["profile"] = profile
                }
                json["schemaVersion"] = 2
                version = 2

            case 2:
                // v2 → v3: Add voiceName
                if var profile = json["profile"] as? [String: Any] {
                    if profile["voiceName"] == nil {
                        profile["voiceName"] = NSNull()
                    }
                    json["profile"] = profile
                }
                json["schemaVersion"] = 3
                version = 3

            default:
                return .failure(ImportError(message: "No migration from v\(version) to v\(version + 1)"))
            }
        }

        guard let migratedData = try? JSONSerialization.data(withJSONObject: json) else {
            return .failure(ImportError(message: "Failed to serialize migrated data."))
        }

        return .success(migratedData)
    }
}
