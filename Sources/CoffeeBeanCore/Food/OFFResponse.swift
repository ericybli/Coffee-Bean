import Foundation

/// A JSON number that may arrive as Double, Int, or a numeric String (Open Food Facts is inconsistent).
struct LenientDouble: Decodable {
    let value: Double?
    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let d = try? c.decode(Double.self) { value = d }
        else if let i = try? c.decode(Int.self) { value = Double(i) }
        else if let s = try? c.decode(String.self) { value = Double(s) }
        else { value = nil }
    }
}

public struct OFFResponse: Decodable, Sendable {
    public let status: Int?
    public let statusVerbose: String?
    public let code: String?
    public let product: OFFProduct?

    enum CodingKeys: String, CodingKey {
        case status, code
        case statusVerbose = "status_verbose"
        case product
    }
}

public struct OFFProduct: Decodable, Sendable {
    public let productName: String?
    public let brands: String?
    public let servingSize: String?
    public let servingQuantity: Double?
    public let nutritionDataPer: String?
    public let imageFrontSmallURL: String?
    public let nutriments: [String: Double]

    enum CodingKeys: String, CodingKey {
        case productName = "product_name"
        case brands
        case servingSize = "serving_size"
        case servingQuantity = "serving_quantity"
        case nutritionDataPer = "nutrition_data_per"
        case imageFrontSmallURL = "image_front_small_url"
        case nutriments
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        productName = try c.decodeIfPresent(String.self, forKey: .productName)
        brands = try c.decodeIfPresent(String.self, forKey: .brands)
        servingSize = try c.decodeIfPresent(String.self, forKey: .servingSize)
        servingQuantity = (try c.decodeIfPresent(LenientDouble.self, forKey: .servingQuantity))?.value
        nutritionDataPer = try c.decodeIfPresent(String.self, forKey: .nutritionDataPer)
        imageFrontSmallURL = try c.decodeIfPresent(String.self, forKey: .imageFrontSmallURL)
        let raw = try c.decodeIfPresent([String: LenientDouble].self, forKey: .nutriments) ?? [:]
        nutriments = raw.compactMapValues(\.value)
    }
}
