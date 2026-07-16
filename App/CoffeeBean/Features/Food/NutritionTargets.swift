import Foundation
import CoffeeBeanCore

/// Daily energy + macro targets. v1 has no HealthKit active energy, so TDEE is seeded
/// from RMR × PAL (the spec's static-seed option); adaptive TDEE arrives in v2.
struct NutritionTargets {
    let tdee: Double
    let calorieTarget: Double
    let macroTargets: Macros

    init(rmr: Double, pal: Double = 1.45, surplusKcal: Double = 250, split: MacroSplit = .default) {
        tdee = rmr * pal
        calorieTarget = tdee + surplusKcal
        macroTargets = split.grams(forCalories: calorieTarget)
    }
}
