// TB3 iOS — Onboarding Step 2: Choose Template

import SwiftUI

struct Step2TemplateView: View {
    @Bindable var vm: OnboardingViewModel
    @Environment(AppState.self) var appState

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Choose a Template")
                    .font(.title2.bold())

                // Day filter
                HStack(spacing: 8) {
                    dayFilterButton(nil, label: "All")
                    dayFilterButton(2, label: "2/wk")
                    dayFilterButton(3, label: "3/wk")
                    dayFilterButton(4, label: "4/wk")
                }

                // Template cards
                ForEach(vm.filteredTemplates, id: \.id) { template in
                    templateCard(template)
                }

                // Lift selection (if template requires it)
                if let template = vm.selectedTemplate {
                    let slots = collectLiftSlots(template)
                    if !slots.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Select Your Lifts")
                                .font(.headline)

                            ForEach(slots, id: \.label) { slot in
                                liftSlotPicker(slot)
                            }
                        }
                        .padding()
                        .background(Color.tb3Card)
                        .cornerRadius(12)
                    }
                }
            }
            .padding()
        }
    }

    private func dayFilterButton(_ days: Int?, label: String) -> some View {
        Button(label) {
            vm.dayFilter = days
        }
        .buttonStyle(.bordered)
        .tint(vm.dayFilter == days ? Color.tb3Accent : Color.tb3Muted)
    }

    private func templateCard(_ template: TemplateDef) -> some View {
        let isSelected = vm.selectedTemplateId == template.id.rawValue

        return Button {
            vm.selectedTemplateId = template.id.rawValue
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(template.name)
                        .font(.headline)
                    Spacer()
                    Text("\(template.sessionsPerWeek)/wk")
                        .font(.caption)
                        .foregroundStyle(Color.tb3Muted)
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.tb3Accent)
                    }
                }
                Text(template.description)
                    .font(.subheadline)
                    .foregroundStyle(Color.tb3Muted)
                    .multilineTextAlignment(.leading)
            }
            .padding()
            .background(isSelected ? Color.tb3Accent.opacity(0.1) : Color.tb3Card)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.tb3Accent : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Lift Slots

    struct LiftSlot {
        let cluster: String
        let label: String
        let options: [String]
        let defaults: [String]
        let minLifts: Int
        let maxLifts: Int
    }

    private func collectLiftSlots(_ template: TemplateDef) -> [LiftSlot] {
        guard let liftSlots = template.liftSlots else { return [] }
        return liftSlots.map { slot in
            LiftSlot(
                cluster: slot.cluster,
                label: slot.label,
                options: LiftName.allCases.map(\.rawValue),
                defaults: slot.defaults,
                minLifts: slot.minLifts,
                maxLifts: slot.maxLifts
            )
        }
    }

    private func liftSlotPicker(_ slot: LiftSlot) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(slot.label)
                .font(.subheadline.bold())
            Text("Select \(slot.minLifts)-\(slot.maxLifts) lifts")
                .font(.caption)
                .foregroundStyle(Color.tb3Muted)

            FlowLayout(spacing: 8) {
                ForEach(slot.options, id: \.self) { option in
                    let isSelected = vm.isLiftSelected(option, slotLabel: slot.cluster)
                    let hasMax = appState.currentLifts.contains { $0.name == option }

                    Button {
                        vm.toggleLift(slotLabel: slot.cluster, liftName: option, minLifts: slot.minLifts, maxLifts: slot.maxLifts)
                    } label: {
                        HStack(spacing: 4) {
                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.caption2)
                            }
                            Text(LiftName(rawValue: option)?.displayName ?? option)
                                .font(.subheadline)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(isSelected ? Color.tb3Accent.opacity(0.15) : Color.tb3Card)
                        .foregroundStyle(hasMax ? .primary : .secondary)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .disabled(!hasMax)
                }
            }
        }
    }
}

// Simple flow layout for lift chips
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, origin) in result.origins.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + origin.x, y: bounds.minY + origin.y), proposal: .unspecified)
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, origins: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var origins: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            origins.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), origins)
    }
}
