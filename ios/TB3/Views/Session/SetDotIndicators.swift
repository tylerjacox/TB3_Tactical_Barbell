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
            }
        }
    }
}
