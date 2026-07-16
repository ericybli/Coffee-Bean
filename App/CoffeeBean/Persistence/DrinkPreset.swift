import Foundation
import SwiftData

/// A one-tap quick-add preset. Generic over drink type so v2 caffeine reuses it.
@Model
final class DrinkPreset {
    var id: UUID = UUID()
    var label: String = ""
    var volumeMl: Double = 250
    var drinkTypeRaw: String = "water"
    var iconName: String = "drop.fill"
    var sortIndex: Int = 0

    init(label: String, volumeMl: Double, drinkTypeRaw: String = "water",
         iconName: String = "drop.fill", sortIndex: Int = 0) {
        self.label = label
        self.volumeMl = volumeMl
        self.drinkTypeRaw = drinkTypeRaw
        self.iconName = iconName
        self.sortIndex = sortIndex
    }
}
