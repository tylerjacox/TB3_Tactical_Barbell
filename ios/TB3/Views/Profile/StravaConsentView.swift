// TB3 iOS — Strava Consent View (shown before OAuth)

import SwiftUI

struct StravaConsentView: View {
    let onConnect: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.title2)
                    .foregroundStyle(Color(hex: 0xFC4C02))
                Text("Connect to Strava")
                    .font(.headline)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("TB3 will share the following when you complete a workout:")
                    .font(.subheadline)
                    .foregroundStyle(Color.tb3Muted)

                bulletList([
                    "Workout date, time, and duration",
                    "Exercise names, weights, sets, and reps",
                    "Program name and week number",
                ])

                Text("TB3 will NOT share:")
                    .font(.subheadline)
                    .foregroundStyle(Color.tb3Muted)
                    .padding(.top, 4)

                bulletList([
                    "Your body weight or personal information",
                    "Your 1RM values or training maxes",
                ])
            }

            Text("You can disconnect at any time from Settings.")
                .font(.caption)
                .foregroundStyle(Color.tb3Disabled)

            HStack(spacing: 12) {
                Button("Cancel") { onCancel() }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)

                Button("Connect") { onConnect() }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(hex: 0xFC4C02))
                    .frame(maxWidth: .infinity)
            }
            .padding(.top, 8)
        }
        .padding(24)
        .background(Color.tb3Card)
        .cornerRadius(16)
        .padding(.horizontal, 24)
    }

    private func bulletList(_ items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                        .font(.subheadline)
                        .foregroundStyle(Color.tb3Muted)
                    Text(item)
                        .font(.subheadline)
                }
            }
        }
        .padding(.leading, 8)
    }
}
