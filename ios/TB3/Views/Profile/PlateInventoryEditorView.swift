// TB3 iOS — Plate Inventory Editor

import SwiftUI

struct PlateInventoryEditorView: View {
    @Binding var inventory: PlateInventory
    var title: String

    var body: some View {
        Form {
            ForEach(inventory.plates.indices, id: \.self) { index in
                plateRow(index: index)
            }
        }
        .navigationTitle(title)
    }

    private func plateRow(index: Int) -> some View {
        let plate = inventory.plates[index]
        let countBinding = Binding<Int>(
            get: { inventory.plates[index].available },
            set: { inventory.plates[index].available = max(0, $0) }
        )
        return HStack {
            Text(formatWeight(plate.weight) + " lb")
                .font(.body)
            Spacer()
            Stepper("\(plate.available)", value: countBinding, in: 0...20)
        }
    }

    private func formatWeight(_ w: Double) -> String {
        w.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(w))" : String(format: "%.1f", w)
    }
}
