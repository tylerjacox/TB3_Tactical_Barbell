// TB3 iOS — Exercise Dot Indicators (horizontal pager dots)

import SwiftUI

struct ExerciseDotIndicators: View {
    let exercises: [ActiveSessionExercise]
    let sets: [SessionSet]
    let currentIndex: Int
    var onSelect: ((Int) -> Void)?

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(exercises.enumerated()), id: \.offset) { index, _ in
                let isDone = sets.filter { $0.exerciseIndex == index }.allSatisfy(\.completed)
                let isCurrent = index == currentIndex

                Circle()
                    .fill(dotColor(isCurrent: isCurrent, isDone: isDone))
                    .frame(width: isCurrent ? 10 : 8, height: isCurrent ? 10 : 8)
                    .animation(.easeInOut(duration: 0.2), value: currentIndex)
                    .onTapGesture {
                        onSelect?(index)
                    }
                    .accessibilityLabel("Exercise \(index + 1) of \(exercises.count), \(exercises[index].liftName)\(isDone ? ", complete" : "")")
                    .accessibilityHint("Double tap to switch to this exercise")
            }
        }
    }

    private func dotColor(isCurrent: Bool, isDone: Bool) -> Color {
        if isDone { return .tb3Accent }
        if isCurrent { return .tb3Accent }
        return .tb3Border
    }
}
