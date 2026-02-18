// TB3 iOS — Set Dot Indicators (completed/pending set dots)

import SwiftUI

struct SetDotIndicators: View {
    let sets: [SessionSet]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(sets.enumerated()), id: \.offset) { _, set in
                Circle()
                    .fill(set.completed ? Color.tb3Accent : Color.tb3Border)
                    .frame(width: 16, height: 16)
                    .scaleEffect(set.completed ? 1.0 : 0.85)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: set.completed)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Set progress, \(sets.filter(\.completed).count) of \(sets.count) sets complete")
    }
}
