import Foundation
import SwiftData

/// A food in the personal library. Nutrition stored per-100g; one named default serving.
/// (Multiple named servings can come later.) Authored to CloudKit-sync rules.
@Model
final class Food {
    var id: UUID = UUID()
    var name: String = ""
    var brand: String? = nil
    var barcode: String? = nil
    var sourceRaw: String = "manual"     // "manual" | "openFoodFacts"
    var isFavorite: Bool = false
    var kcalPer100g: Double = 0
    var proteinPer100g: Double = 0
    var carbPer100g: Double = 0
    var fatPer100g: Double = 0
    var servingLabel: String = "100 g"
    var servingGrams: Double = 100
    var lastUsedAt: Date = Date.distantPast

    init(name: String, brand: String? = nil, barcode: String? = nil, sourceRaw: String = "manual",
         isFavorite: Bool = false, kcalPer100g: Double = 0, proteinPer100g: Double = 0,
         carbPer100g: Double = 0, fatPer100g: Double = 0,
         servingLabel: String = "100 g", servingGrams: Double = 100) {
        self.name = name
        self.brand = brand
        self.barcode = barcode
        self.sourceRaw = sourceRaw
        self.isFavorite = isFavorite
        self.kcalPer100g = kcalPer100g
        self.proteinPer100g = proteinPer100g
        self.carbPer100g = carbPer100g
        self.fatPer100g = fatPer100g
        self.servingLabel = servingLabel
        self.servingGrams = servingGrams
    }
}

extension Food {
    /// Macro totals for `servings` of this food's serving.
    func totals(servings: Double) -> (kcal: Double, protein: Double, carb: Double, fat: Double) {
        let f = servingGrams / 100 * servings
        return (kcalPer100g * f, proteinPer100g * f, carbPer100g * f, fatPer100g * f)
    }
}
