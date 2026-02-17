// TB3 iOS — Onboarding Step 1: Enter Lift Maxes

import SwiftUI

struct Step1LiftsView: View {
    @Bindable var vm: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Enter Your Lifts")
                    .font(.title2.bold())

                Text("Enter weight and reps from your most recent test for each lift. Leave blank to skip.")
                    .font(.subheadline)
                    .foregroundStyle(Color.tb3Muted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                ForEach(LiftName.allCases, id: \.rawValue) { lift in
                    liftRow(lift)
                }
            }
            .padding()
        }
    }

    private func liftRow(_ lift: LiftName) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(lift.displayName)
                .font(.headline)

            HStack(spacing: 12) {
                HStack {
                    TextField("Weight", text: binding(for: lift, keyPath: \.weight))
                        .keyboardType(.decimalPad)
                        .frame(width: 80)
                        .padding(10)
                        .background(Color.tb3Card)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.tb3Border, lineWidth: 1))
                    Text("lb")
                        .foregroundStyle(Color.tb3Muted)
                }

                Text("\u{00D7}")
                    .foregroundStyle(Color.tb3Muted)

                HStack {
                    TextField("Reps", text: binding(for: lift, keyPath: \.reps))
                        .keyboardType(.numberPad)
                        .frame(width: 60)
                        .padding(10)
                        .background(Color.tb3Card)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.tb3Border, lineWidth: 1))
                    Text("reps")
                        .foregroundStyle(Color.tb3Muted)
                }

                Spacer()

                // Show calculated 1RM
                if let calculated = calculatedMax(for: lift) {
                    Text("\(Int(calculated)) 1RM")
                        .font(.caption)
                        .foregroundStyle(Color.tb3Muted)
                }
            }
        }
        .padding()
        .background(Color.tb3Card)
        .cornerRadius(12)
    }

    private func binding(for lift: LiftName, keyPath: WritableKeyPath<OnboardingViewModel.LiftInput, String>) -> Binding<String> {
        Binding(
            get: { vm.liftInputs[lift.rawValue]?[keyPath: keyPath] ?? "" },
            set: { vm.liftInputs[lift.rawValue]?[keyPath: keyPath] = $0 }
        )
    }

    private func calculatedMax(for lift: LiftName) -> Double? {
        guard let input = vm.liftInputs[lift.rawValue],
              let weight = Double(input.weight), weight > 0,
              let reps = Int(input.reps), reps > 0 else { return nil }
        return OneRepMaxCalculator.calculateOneRepMax(weight: weight, reps: reps)
    }
}

extension LiftName {
    var displayName: String {
        switch self {
        case .bench: return "Bench Press"
        case .squat: return "Squat"
        case .deadlift: return "Deadlift"
        case .militaryPress: return "Overhead Press"
        case .weightedPullUp: return "Weighted Pull-Up"
        }
    }
}
