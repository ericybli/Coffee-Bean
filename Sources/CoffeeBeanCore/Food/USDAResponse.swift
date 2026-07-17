import Foundation

public struct USDASearchResponse: Decodable, Sendable {
    public let totalHits: Int?
    public let foods: [USDAFood]
}

public struct USDAFood: Decodable, Sendable {
    public let description: String?
    public let dataType: String?
    public let brandOwner: String?
    public let gtinUpc: String?
    public let foodNutrients: [USDANutrient]

    enum CodingKeys: String, CodingKey {
        case description, dataType, brandOwner, gtinUpc, foodNutrients
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        description = try c.decodeIfPresent(String.self, forKey: .description)
        dataType = try c.decodeIfPresent(String.self, forKey: .dataType)
        brandOwner = try c.decodeIfPresent(String.self, forKey: .brandOwner)
        gtinUpc = try c.decodeIfPresent(String.self, forKey: .gtinUpc)
        foodNutrients = try c.decodeIfPresent([USDANutrient].self, forKey: .foodNutrients) ?? []
    }
}

public struct USDANutrient: Decodable, Sendable {
    /// FDC "nutrient number" — a short code like "208" (energy kcal).
    /// Usually a string; tolerate a bare number.
    public let nutrientNumber: String?
    public let value: Double?

    enum CodingKeys: String, CodingKey { case nutrientNumber, value }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let s = try? c.decodeIfPresent(String.self, forKey: .nutrientNumber) { nutrientNumber = s }
        else if let i = try? c.decodeIfPresent(Int.self, forKey: .nutrientNumber) { nutrientNumber = String(i) }
        else { nutrientNumber = nil }
        value = (try? c.decodeIfPresent(Double.self, forKey: .value)) ?? nil
    }
}
