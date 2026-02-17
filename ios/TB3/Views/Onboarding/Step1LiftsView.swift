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
            HStack {
                Text(lift.displayName)
                    .font(.headline)
                Spacer()
                if let calculated = calculatedMax(for: lift) {
                    Text("\(Int(calculated)) 1RM")
                        .font(.subheadline)
                        .foregroundStyle(Color.tb3Accent)
                }
            }

            WeightRepsPicker(
                weightText: binding(for: lift, keyPath: \.weight),
                repsText: binding(for: lift, keyPath: \.reps)
            )

            // Plate visualizer
            if let plateResult = plateResult(for: lift) {
                PlateDisplayView(
                    result: plateResult,
                    isBodyweight: lift == .weightedPullUp
                )
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

    private func plateResult(for lift: LiftName) -> PlateResult? {
        guard let input = vm.liftInputs[lift.rawValue],
              let weight = Double(input.weight), weight > 0 else { return nil }
        if lift == .weightedPullUp {
            return PlateCalculator.calculateBeltPlates(
                totalWeight: weight,
                inventory: DEFAULT_PLATE_INVENTORY_BELT
            )
        }
        return PlateCalculator.calculateBarbellPlates(
            totalWeight: weight,
            barbellWeight: 45,
            inventory: DEFAULT_PLATE_INVENTORY_BARBELL
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
