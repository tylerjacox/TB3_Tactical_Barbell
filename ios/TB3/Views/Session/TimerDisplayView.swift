// TB3 iOS — Timer Display View (two-phase: rest count-up + exercise count-up)

import SwiftUI

struct TimerDisplayView: View {
    let elapsed: TimeInterval // seconds
    let phase: TimerPhase?
    let isOvertime: Bool

    var body: some View {
        VStack(spacing: 4) {
            // Phase label
            Text(phaseLabel)
                .font(.subheadline.bold())
                .foregroundStyle(Color.tb3Muted)

            // Time display
            Text(formatTime(elapsed))
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundStyle(timerColor)
        }
    }

    private var phaseLabel: String {
        switch phase {
        case .rest: return isOvertime ? "REST (OVERTIME)" : "REST"
        case .exercise: return "EXERCISE"
        case nil: return ""
        }
    }

    private var timerColor: Color {
        switch phase {
        case .rest: return isOvertime ? .timerOvertime : .timerRest
        case .exercise: return .timerExercise
        case nil: return Color.tb3Text
        }
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds)
        let minutes = totalSeconds / 60
        let secs = totalSeconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}
