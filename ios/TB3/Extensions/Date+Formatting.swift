// TB3 iOS — Date Formatting Extensions

import Foundation

extension Date {
    /// ISO 8601 string (matching PWA's new Date().toISOString())
    var iso8601: String {
        ISO8601DateFormatter().string(from: self)
    }

    /// ISO 8601 string for current time
    static func iso8601Now() -> String {
        Date().iso8601
    }

    /// Generate a UUID string (matching PWA's generateId())
    static func generateId() -> String {
        UUID().uuidString.lowercased()
    }

    /// Parse ISO 8601 string
    static func fromISO8601(_ string: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: string) ?? ISO8601DateFormatter().date(from: string)
    }

    /// Display format: "Jan 15, 2024"
    var shortDisplay: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }

    /// Display format: "Jan 15, 2024 at 3:30 PM"
    var fullDisplay: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}

extension String {
    /// Parse this string as an ISO 8601 date
    var asDate: Date? {
        Date.fromISO8601(self)
    }
}

/// Generate a UUID string (matching PWA's generateId())
func generateId() -> String {
    UUID().uuidString.lowercased()
}
