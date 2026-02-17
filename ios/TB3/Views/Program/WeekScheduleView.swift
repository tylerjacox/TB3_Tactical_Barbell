// TB3 iOS — Week Schedule View (collapsible week with sessions)

import SwiftUI

struct WeekScheduleView: View {
    let week: ComputedWeek
    var isCurrent: Bool = false
    var defaultOpen: Bool = false

    @State private var isExpanded: Bool

    init(week: ComputedWeek, isCurrent: Bool = false, defaultOpen: Bool = false) {
        self.week = week
        self.isCurrent = isCurrent
        self.defaultOpen = defaultOpen
        _isExpanded = State(initialValue: defaultOpen || isCurrent)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "chevron.right")
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .font(.caption)

                    Text(week.label)
                        .font(.headline)

                    Text("@ \(week.percentage)%")
                        .font(.caption)
                        .foregroundStyle(Color.tb3Muted)

                    if isCurrent {
                        Text("Current")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.tb3Accent.opacity(0.2))
                            .foregroundColor(.tb3Accent)
                            .cornerRadius(4)
                    }

                    Spacer()

                    if let min = week.minSets, let max = week.maxSets, min != max {
                        Text("\(min)-\(max) sets")
                            .font(.caption)
                            .foregroundStyle(Color.tb3Muted)
                    } else if let max = week.maxSets {
                        Text("\(max) sets")
                            .font(.caption)
                            .foregroundStyle(Color.tb3Muted)
                    }
                }
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Sessions
            if isExpanded {
                ForEach(Array(week.sessions.enumerated()), id: \.offset) { _, session in
                    SessionPreviewCard(session: session, week: week, compact: true)
                        .padding(.bottom, 8)
                }
            }
        }
    }
}
