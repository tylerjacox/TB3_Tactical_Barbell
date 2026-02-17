// TB3 iOS — Session Preview Card (shows exercises for a session)

import SwiftUI

struct SessionPreviewCard: View {
    let session: ComputedSession
    let week: ComputedWeek
    var compact: Bool = false

    @Environment(AppState.self) var appState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(session.label)
                .font(.headline)

            ForEach(Array(session.exercises.enumerated()), id: \.offset) { _, exercise in
                exerciseRow(exercise)
            }

            // Sets/reps info
            let setsReps = formatWeekSetsReps()
            Text(setsReps)
                .font(.caption)
                .foregroundStyle(Color.tb3Muted)
        }
        .padding()
        .background(Color.tb3Card)
        .cornerRadius(12)
    }

    private func exerciseRow(_ exercise: ComputedExercise) -> some View {
        HStack {
            Text(LiftName(rawValue: exercise.liftName)?.displayName ?? exercise.liftName)
                .font(.subheadline)

            Spacer()

            if exercise.targetWeight > 0 {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(exercise.targetWeight)) lb")
                        .font(.subheadline.monospaced().bold())
                        .foregroundColor(.tb3Accent)

                    if !compact, !exercise.plates.isEmpty {
                        Text(formatPlates(exercise.plates))
                            .font(.caption2)
                            .foregroundStyle(Color.tb3Muted)
                    }
                }
            } else if exercise.liftName == LiftName.weightedPullUp.rawValue {
                Text("BW")
                    .font(.subheadline)
                    .foregroundStyle(Color.tb3Muted)
            }
        }
    }

    private func formatPlates(_ plates: [PlateCount]) -> String {
        plates.map { plate in
            if plate.count == 1 {
                return "\(formatWeight(plate.weight))"
            } else {
                return "\(plate.count)\u{00D7}\(formatWeight(plate.weight))"
            }
        }.joined(separator: " + ")
    }

    private func formatWeight(_ w: Double) -> String {
        w.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(w))" : String(format: "%.1f", w)
    }

    private func formatWeekSetsReps() -> String {
        let percentage = "\(week.percentage)%"
        if let minSets = week.minSets, let maxSets = week.maxSets, minSets != maxSets {
            return "\(minSets)-\(maxSets) sets @ \(percentage)"
        } else if let maxSets = week.maxSets {
            return "\(maxSets) sets @ \(percentage)"
        }
        return "@ \(percentage)"
    }
}
