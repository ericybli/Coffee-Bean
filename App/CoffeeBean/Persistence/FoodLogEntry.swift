import Foundation
import SwiftData

/// A logged food (diary row). Snapshots the macros at log time so later edits to the
/// Food never rewrite history. Links back to the library by `foodID` (no relationship,
/// keeping CloudKit-sync rules trivial).
@Model
final class FoodLogEntry {
    var id: UUID = UUID()
    var loggedAt: Date = Date()
    var day: Date = Date()             // startOfDay bucket
    var mealSlotRaw: String = "breakfast"
    var foodID: UUID? = nil
    var foodName: String = ""
    var servingLabel: String = "100 g"
    var quantity: Double = 1
    var kcal: Double = 0
    var proteinG: Double = 0
    var carbG: Double = 0
    var fatG: Double = 0

    init(day: Date, mealSlotRaw: String, foodID: UUID?, foodName: String, servingLabel: String,
         quantity: Double, kcal: Double, proteinG: Double, carbG: Double, fatG: Double,
         loggedAt: Date = Date()) {
        self.day = day
        self.mealSlotRaw = mealSlotRaw
        self.foodID = foodID
        self.foodName = foodName
        self.servingLabel = servingLabel
        self.quantity = quantity
        self.kcal = kcal
        self.proteinG = proteinG
        self.carbG = carbG
        self.fatG = fatG
        self.loggedAt = loggedAt
    }
}
