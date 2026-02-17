// TB3 iOS — Onboarding Step 4: Set Start Date

import SwiftUI

struct Step4StartView: View {
    @Bindable var vm: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 48))
                        .foregroundColor(.tb3Accent)

                    Text("When do you start?")
                        .font(.title2.bold())

                    Text("Pick the Monday of your first training week.")
                        .font(.subheadline)
                        .foregroundStyle(Color.tb3Muted)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 16)

                DatePicker(
                    "Start Date",
                    selection: $vm.startDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)

                if let template = vm.selectedTemplate {
                    VStack(spacing: 4) {
                        Text(template.name)
                            .font(.headline)
                        Text("\(template.durationWeeks) weeks \u{2022} \(template.sessionsPerWeek) sessions/week")
                            .font(.subheadline)
                            .foregroundStyle(Color.tb3Muted)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}
