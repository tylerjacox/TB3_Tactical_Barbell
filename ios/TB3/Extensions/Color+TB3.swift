// TB3 iOS — Theme Colors and Plate Colors

import SwiftUI

extension Color {
    // MARK: - Hex Initializer

    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: alpha
        )
    }

    // MARK: - TB3 Theme (matching web style.css custom properties)

    static let tb3Background  = Color(hex: 0x000000)  // iOS: pure black (matches system dark + OLED)
    static let tb3Card        = Color(hex: 0x1A1A1A)  // --card
    static let tb3Text        = Color(hex: 0xFFFFFF)  // --text
    static let tb3Accent      = Color(hex: 0xFF9500)  // --accent
    static let tb3Muted       = Color(hex: 0x999999)  // --muted
    static let tb3Error       = Color(hex: 0xFF6B6B)  // --error
    static let tb3Success     = Color(hex: 0x4CAF50)  // --success
    static let tb3Disabled    = Color(hex: 0x666666)  // --disabled
    static let tb3Border      = Color(hex: 0x333333)  // --border
    static let tb3Placeholder = Color(hex: 0xAAAAAA)  // --placeholder
    static let tb3TabInactive = Color(hex: 0x888888)

    // MARK: - Plate Colors (matching cast-receiver competition plate colors)

    static let plate45 = Color(red: 0.78, green: 0.16, blue: 0.16) // Red
    static let plate35 = Color(red: 0.85, green: 0.65, blue: 0.13) // Gold
    static let plate25 = Color(red: 0.61, green: 0.15, blue: 0.69) // Purple
    static let plate10 = Color(red: 1.0, green: 0.60, blue: 0.0)   // Orange
    static let plate5 = Color(red: 0.25, green: 0.47, blue: 0.85)  // Blue
    static let plate2_5 = Color(red: 0.30, green: 0.69, blue: 0.31) // Green
    static let plate1_25 = Color(red: 0.75, green: 0.75, blue: 0.75) // Light Gray

    static func plateColor(for weight: Double) -> Color {
        switch weight {
        case 45: return .plate45
        case 35: return .plate35
        case 25: return .plate25
        case 10: return .plate10
        case 5: return .plate5
        case 2.5: return .plate2_5
        case 1.25: return .plate1_25
        default: return .gray
        }
    }

    // MARK: - Lift Chart Colors (matching MaxChart.tsx)

    static let liftSquat = Color(red: 0.78, green: 0.16, blue: 0.16)    // #C62828
    static let liftBench = Color(red: 0.26, green: 0.65, blue: 0.96)    // #42A5F5
    static let liftDeadlift = Color(red: 0.40, green: 0.73, blue: 0.42) // #66BB6A
    static let liftMilitaryPress = Color(red: 0.98, green: 0.66, blue: 0.15) // #F9A825
    static let liftWeightedPullUp = Color(red: 0.48, green: 0.12, blue: 0.64) // #7B1FA2

    static func liftColor(for liftName: String) -> Color {
        switch liftName {
        case "Squat": return .liftSquat
        case "Bench": return .liftBench
        case "Deadlift": return .liftDeadlift
        case "Military Press": return .liftMilitaryPress
        case "Weighted Pull-up": return .liftWeightedPullUp
        default: return .gray
        }
    }

    // MARK: - Timer Colors

    static let timerRest = Color(hex: 0xFF9500)      // --accent (orange)
    static let timerOvertime = Color(hex: 0xFF6B6B)   // --error
    static let timerExercise = Color(hex: 0x4CAF50)   // --success (green)

    // MARK: - Button Colors

    static let beginSetGreen = Color(hex: 0x4CAF50)      // --success
    static let completeSetOrange = Color(hex: 0xFF9500)   // --accent
}
