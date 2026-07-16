import Foundation

/// Percent-of-calories split. carbPct + fatPct + proteinPct == 100.
public struct MacroSplit: Equatable, Sendable {
    public let carbPct: Double
    public let fatPct: Double
    public let proteinPct: Double

    public init(carbPct: Double, fatPct: Double, proteinPct: Double) {
        self.carbPct = carbPct
        self.fatPct = fatPct
        self.proteinPct = proteinPct
    }

    public static let `default` = MacroSplit(carbPct: 50, fatPct: 30, proteinPct: 20)
    public static let highProtein = MacroSplit(carbPct: 40, fatPct: 20, proteinPct: 40)
    public static let keto = MacroSplit(carbPct: 10, fatPct: 65, proteinPct: 25)

    /// Custom split: user sets carbs and fat; protein auto-fills the remainder.
    public static func custom(carbPct: Double, fatPct: Double) -> MacroSplit {
        MacroSplit(carbPct: carbPct, fatPct: fatPct, proteinPct: max(0, 100 - carbPct - fatPct))
    }

    /// Grams for each macro given a calorie target (carb/protein 4 kcal/g, fat 9 kcal/g).
    public func grams(forCalories calories: Double) -> Macros {
        Macros(
            proteinG: (proteinPct / 100 * calories) / kcalPerGramProtein,
            carbG:    (carbPct / 100 * calories) / kcalPerGramCarb,
            fatG:     (fatPct / 100 * calories) / kcalPerGramFat
        )
    }
}
