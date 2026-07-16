import Foundation

public enum OpenFoodFactsParser {
    private static let kjPerKcal = 4.184

    /// Normalize an OFF response to a usable RemoteFood, or nil if not found / not nutritionally usable.
    public static func parse(_ response: OFFResponse, barcode: String) -> RemoteFood? {
        // "found" requires status == 1 and a product with a name.
        guard response.status == 1, let p = response.product,
              let name = p.productName, !name.isEmpty else { return nil }

        // Usable energy: direct kcal, else derive from kJ.
        let kcal: Double?
        if let direct = p.nutriments["energy-kcal_100g"] {
            kcal = direct
        } else if let kj = p.nutriments["energy-kj_100g"] {
            kcal = kj / kjPerKcal
        } else {
            kcal = nil
        }
        guard let energy = kcal else { return nil }

        return RemoteFood(
            barcode: barcode,
            name: name,
            brand: p.brands,
            kcalPer100g: energy,
            proteinPer100g: p.nutriments["proteins_100g"] ?? 0,
            carbPer100g: p.nutriments["carbohydrates_100g"] ?? 0,
            fatPer100g: p.nutriments["fat_100g"] ?? 0,
            servingSizeText: p.servingSize,
            imageURL: p.imageFrontSmallURL
        )
    }
}
