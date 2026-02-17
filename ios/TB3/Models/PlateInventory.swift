// TB3 iOS — Plate Inventory (mirrors types.ts PlateInventory)

import Foundation

struct PlateEntry: Codable, Equatable {
    var weight: Double
    var available: Int
}

struct PlateInventory: Codable, Equatable {
    var plates: [PlateEntry]
}

let DEFAULT_PLATE_INVENTORY_BARBELL = PlateInventory(plates: [
    PlateEntry(weight: 45, available: 4),
    PlateEntry(weight: 35, available: 1),
    PlateEntry(weight: 25, available: 1),
    PlateEntry(weight: 10, available: 2),
    PlateEntry(weight: 5, available: 1),
    PlateEntry(weight: 2.5, available: 1),
    PlateEntry(weight: 1.25, available: 1),
])

let DEFAULT_PLATE_INVENTORY_BELT = PlateInventory(plates: [
    PlateEntry(weight: 45, available: 2),
    PlateEntry(weight: 35, available: 1),
    PlateEntry(weight: 25, available: 1),
    PlateEntry(weight: 10, available: 2),
    PlateEntry(weight: 5, available: 1),
    PlateEntry(weight: 2.5, available: 1),
    PlateEntry(weight: 1.25, available: 1),
])
