import Foundation
import CoffeeBeanCore

/// Daily energy + macro targets, driven by the profile's §7 settings
/// (Fixed vs ±TDEE calorie mode, macro-split preset). TDEE is RMR × PAL
/// until HealthKit active energy / adaptive TDEE arrive.
struct NutritionTargets {
    let tdee: Double
    let calorieTarget: Double
    let macroTargets: Macros

    init(rmr: Double, profile: Profile?) {
        tdee = EnergyResolver.tdee(rmr: rmr)
        calorieTarget = (profile?.calorieTarget ?? .tdeeOffset(250)).resolve(tdee: tdee)
        macroTargets = (profile?.macroSplit ?? .default).grams(forCalories: calorieTarget)
    }
}
