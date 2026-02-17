// TB3 iOS — Max Chart View (Swift Charts 1RM progression)

import SwiftUI
import Charts

struct MaxChartView: View {
    let maxTests: [SyncOneRepMaxTest]

    @State private var selectedLift: String?

    var body: some View {
        VStack(spacing: 16) {
            // Lift filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    filterButton(nil, label: "All")
                    ForEach(availableLifts, id: \.self) { lift in
                        filterButton(lift, label: LiftName(rawValue: lift)?.displayName ?? lift)
                    }
                }
                .padding(.horizontal)
            }

            if filteredTests.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.tb3Muted)
                    Text("No max test data yet")
                        .font(.subheadline)
                        .foregroundStyle(Color.tb3Muted)
                    Spacer()
                }
            } else {
                Chart {
                    ForEach(filteredTests, id: \.id) { test in
                        if let date = Date.fromISO8601(test.date) {
                            LineMark(
                                x: .value("Date", date),
                                y: .value("1RM", test.calculatedMax)
                            )
                            .foregroundStyle(by: .value("Lift", LiftName(rawValue: test.liftName)?.displayName ?? test.liftName))

                            PointMark(
                                x: .value("Date", date),
                                y: .value("1RM", test.calculatedMax)
                            )
                            .foregroundStyle(by: .value("Lift", LiftName(rawValue: test.liftName)?.displayName ?? test.liftName))
                        }
                    }
                }
                .chartYAxisLabel("1RM (lb)")
                .chartLegend(position: .bottom)
                .frame(height: 250)
                .padding(.horizontal)
            }
        }
    }

    private var availableLifts: [String] {
        Array(Set(maxTests.map(\.liftName))).sorted()
    }

    private var filteredTests: [SyncOneRepMaxTest] {
        let tests: [SyncOneRepMaxTest]
        if let lift = selectedLift {
            tests = maxTests.filter { $0.liftName == lift }
        } else {
            tests = maxTests
        }
        return tests.sorted { $0.date < $1.date }
    }

    private func filterButton(_ lift: String?, label: String) -> some View {
        Button(label) {
            selectedLift = lift
        }
        .buttonStyle(.bordered)
        .tint(selectedLift == lift ? Color.tb3Accent : Color.tb3Muted)
        .controlSize(.small)
    }
}
