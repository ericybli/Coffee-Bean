import Foundation
import SwiftData

/// A logged drink. `drinkTypeRaw` + optional `caffeineMg` let v2 caffeine reuse this model.
@Model
final class DrinkLog {
    var id: UUID = UUID()
    var timestamp: Date = Date()
    var volumeMl: Double = 0
    var drinkTypeRaw: String = "water"
    var name: String = "Water"
    var caffeineMg: Double? = nil

    init(timestamp: Date = Date(), volumeMl: Double = 0, drinkTypeRaw: String = "water",
         name: String = "Water", caffeineMg: Double? = nil) {
        self.timestamp = timestamp
        self.volumeMl = volumeMl
        self.drinkTypeRaw = drinkTypeRaw
        self.name = name
        self.caffeineMg = caffeineMg
    }
}
