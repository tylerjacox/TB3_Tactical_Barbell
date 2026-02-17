// TB3 iOS — History View (session logs + max test history)

import SwiftUI

struct HistoryView: View {
    @Environment(AppState.self) var appState
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: "History")

            Picker("View", selection: $selectedTab) {
                Text("Chart").tag(0)
                Text("Max Tests").tag(1)
                Text("Sessions").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)

            switch selectedTab {
            case 0:
                MaxChartView(maxTests: appState.maxTestHistory)
            case 1:
                maxTestList
            default:
                sessionList
            }
        }
        .background(Color.tb3Background)
    }

    // MARK: - Sessions

    private var sessionList: some View {
        Group {
            if appState.sessionHistory.isEmpty {
                emptyState("No sessions yet", icon: "figure.strengthtraining.traditional")
            } else {
                List {
                    ForEach(appState.sessionHistory.sorted(by: { $0.date > $1.date }), id: \.id) { session in
                        SessionLogRow(session: session)
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    // MARK: - Max Tests

    private var maxTestList: some View {
        Group {
            if appState.maxTestHistory.isEmpty {
                emptyState("No max tests yet", icon: "chart.line.uptrend.xyaxis")
            } else {
                List {
                    ForEach(LiftName.allCases, id: \.rawValue) { lift in
                        let tests = appState.maxTestHistory
                            .filter { $0.liftName == lift.rawValue }
                            .sorted { $0.date > $1.date }

                        if !tests.isEmpty {
                            Section(lift.displayName) {
                                ForEach(tests, id: \.id) { test in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("\(Int(test.weight)) lb \u{00D7} \(test.reps) reps")
                                                .font(.subheadline)
                                            Text("1RM: \(Int(test.calculatedMax)) lb (\(test.maxType))")
                                                .font(.caption)
                                                .foregroundStyle(Color.tb3Muted)
                                        }
                                        Spacer()
                                        if let date = Date.fromISO8601(test.date) {
                                            Text(date.shortDisplay)
                                                .font(.caption)
                                                .foregroundStyle(Color.tb3Disabled)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
    }

    private func emptyState(_ message: String, icon: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(Color.tb3Muted)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Color.tb3Muted)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Session Log Row

struct SessionLogRow: View {
    let session: SyncSessionLog
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation { isExpanded.toggle() }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(session.templateId.capitalized)
                            .font(.subheadline.bold())
                        Text("Week \(session.week) \u{2022} Session \(session.sessionNumber)")
                            .font(.caption)
                            .foregroundStyle(Color.tb3Muted)
                    }
                    Spacer()
                    if let date = Date.fromISO8601(session.date) {
                        Text(date.shortDisplay)
                            .font(.caption)
                            .foregroundStyle(Color.tb3Disabled)
                    }
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(Color.tb3Disabled)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                ForEach(Array(session.exercises.enumerated()), id: \.offset) { _, exercise in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(LiftName(rawValue: exercise.liftName)?.displayName ?? exercise.liftName)
                            .font(.caption.bold())

                        let setsText = exercise.sets.enumerated().map { i, set in
                            "Set \(i+1): \(set.actualReps) reps"
                        }.joined(separator: ", ")
                        let weightText = "\(Int(exercise.targetWeight)) lb"

                        Text("\(weightText) — \(setsText)")
                            .font(.caption)
                            .foregroundStyle(Color.tb3Muted)
                    }
                    .padding(.leading, 12)
                }
            }
        }
    }
}
