import Foundation

public let kcalPerGramProtein = 4.0
public let kcalPerGramCarb = 4.0
public let kcalPerGramFat = 9.0

public struct Macros: Equatable, Sendable {
    public let proteinG: Double
    public let carbG: Double
    public let fatG: Double
    public init(proteinG: Double, carbG: Double, fatG: Double) {
        self.proteinG = proteinG
        self.carbG = carbG
        self.fatG = fatG
    }
    public var kcal: Double {
        proteinG * kcalPerGramProtein + carbG * kcalPerGramCarb + fatG * kcalPerGramFat
    }
}
