import Foundation

public struct RemoteFood: Equatable, Sendable {
    public let barcode: String?
    public let name: String
    public let brand: String?
    public let kcalPer100g: Double
    public let proteinPer100g: Double
    public let carbPer100g: Double
    public let fatPer100g: Double
    public let servingSizeText: String?
    public let imageURL: String?

    public init(barcode: String?, name: String, brand: String?,
                kcalPer100g: Double, proteinPer100g: Double, carbPer100g: Double,
                fatPer100g: Double, servingSizeText: String?, imageURL: String?) {
        self.barcode = barcode
        self.name = name
        self.brand = brand
        self.kcalPer100g = kcalPer100g
        self.proteinPer100g = proteinPer100g
        self.carbPer100g = carbPer100g
        self.fatPer100g = fatPer100g
        self.servingSizeText = servingSizeText
        self.imageURL = imageURL
    }
}
