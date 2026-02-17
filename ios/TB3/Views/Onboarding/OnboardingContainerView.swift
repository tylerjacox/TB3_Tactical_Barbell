// TB3 iOS — Onboarding Container (4-step wizard)

import SwiftUI

struct OnboardingContainerView: View {
    @State private var vm: OnboardingViewModel

    init(appState: AppState, dataStore: DataStore) {
        _vm = State(initialValue: OnboardingViewModel(appState: appState, dataStore: dataStore))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Step indicator
            HStack(spacing: 8) {
                ForEach(1...4, id: \.self) { i in
                    Capsule()
                        .fill(i <= vm.step ? Color.tb3Accent : Color.tb3Border)
                        .frame(height: 4)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)

            // Content
            Group {
                switch vm.step {
                case 1: Step1LiftsView(vm: vm)
                case 2: Step2TemplateView(vm: vm)
                case 3: Step3PreviewView(vm: vm)
                case 4: Step4StartView(vm: vm)
                default: EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Navigation buttons
            HStack {
                if vm.step > 1 {
                    Button("Back") {
                        vm.back()
                    }
                    .buttonStyle(.bordered)
                }

                Spacer()

                Button(vm.step == 4 ? "Start Training" : "Continue") {
                    vm.next()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!vm.canContinue)
            }
            .padding()
        }
    }
}
