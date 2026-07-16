import Foundation
import CoffeeBeanCore

/// App-wide Open Food Facts client (barcode → nutrition) with the required custom User-Agent.
enum OFFService {
    private static let client = OpenFoodFactsClient(
        userAgent: "CoffeeBean/0.1 (engineering@month2month.com)")

    static func lookup(barcode: String) async throws -> RemoteFood? {
        try await client.lookup(barcode: barcode)
    }
}

extension Food {
    /// Build a library Food from an Open Food Facts result (nutriments are per-100g).
    static func from(_ r: RemoteFood) -> Food {
        Food(name: r.name, brand: r.brand, barcode: r.barcode, sourceRaw: "openFoodFacts",
             kcalPer100g: r.kcalPer100g, proteinPer100g: r.proteinPer100g,
             carbPer100g: r.carbPer100g, fatPer100g: r.fatPer100g,
             servingLabel: r.servingSizeText ?? "100 g", servingGrams: 100)
    }
}
