import Foundation

public enum TEFMode: String, Codable, Sendable { case none, flatTen, perMacro }

public enum TEF {
    /// Thermic effect of food (kcal). perMacro requires macros; without them it falls back to flat 10%.
    public static func value(mode: TEFMode, intakeKcal: Double, macros: Macros?) -> Double {
        switch mode {
        case .none:
            return 0
        case .flatTen:
            return 0.10 * intakeKcal
        case .perMacro:
            guard let m = macros else { return 0.10 * intakeKcal }
            return 0.25 * (m.proteinG * kcalPerGramProtein)
                 + 0.08 * (m.carbG * kcalPerGramCarb)
                 + 0.02 * (m.fatG * kcalPerGramFat)
        }
    }
}
