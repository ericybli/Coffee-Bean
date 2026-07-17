import Foundation
import CoffeeBeanCore

/// App-wide Open Food Facts client (barcode → nutrition) with the required custom User-Agent.
enum OFFService {
    // US mirror: same global DB for barcodes, US-scoped text search results.
    private static let client = OpenFoodFactsClient(
        baseURL: OpenFoodFactsClient.usBaseURL,
        userAgent: "CoffeeBean/0.1 (engineering@month2month.com)")

    static func lookup(barcode: String) async throws -> RemoteFood? {
        try await client.lookup(barcode: barcode)
    }

    static func search(query: String) async throws -> [RemoteFood] {
        try await client.search(query: query)
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
