// TB3 iOS — Core Enums (mirrors types.ts constants)

import Foundation

enum LiftName: String, Codable, CaseIterable, Identifiable {
    case squat = "Squat"
    case bench = "Bench"
    case deadlift = "Deadlift"
    case militaryPress = "Military Press"
    case weightedPullUp = "Weighted Pull-up"

    var id: String { rawValue }

    var isBodyweight: Bool {
        self == .weightedPullUp
    }
}

enum TemplateId: String, Codable, CaseIterable, Identifiable {
    case `operator` = "operator"
    case zulu = "zulu"
    case fighter = "fighter"
    case gladiator = "gladiator"
    case massProtocol = "mass-protocol"
    case massStrength = "mass-strength"
    case greyMan = "grey-man"

    var id: String { rawValue }
}

enum MaxType: String, Codable {
    case `true` = "true"
    case training = "training"
}

enum SoundMode: String, Codable {
    case on
    case off
    case vibrate
}

enum ThemeMode: String, Codable {
    case light
    case dark
    case system
}

enum WeightUnit: String, Codable {
    case lb
    case kg
}

enum SessionStatus: String, Codable {
    case completed
    case partial
    case skipped
}

enum TimerPhase: String, Codable {
    case rest
    case exercise
}

enum WorkoutStatus: String, Codable {
    case inProgress = "in_progress"
    case paused
}

let CURRENT_SCHEMA_VERSION = 3
