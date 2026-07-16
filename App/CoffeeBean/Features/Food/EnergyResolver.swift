import Foundation
import CoffeeBeanCore

/// App-side bridge into CoffeeBeanCore's energy engine: builds Biometrics from the
/// profile + latest data and runs the spec §5.1 RMR priority (DEXA > Katch > Mifflin).
enum EnergyResolver {
    /// v1 static activity seed (no HealthKit active energy yet).
    static let pal = 1.45

    static func rmr(profile: Profile?, scans: [BodyScan], latestWeightKg: Double?) -> RMRResult {
        let measured = scans.first(where: { $0.isRMRAuthoritative && $0.rmrKcal != nil })?.rmrKcal
        let lean = scans.first(where: { $0.leanMassKg != nil })?.leanMassKg
        let bio = Biometrics(
            weightKg: latestWeightKg ?? 75,
            heightCm: profile?.heightCm ?? 178,
            ageYears: profile?.age ?? 30,
            sex: profile?.sexRaw == "female" ? .female : .male,
            bodyFatFraction: nil,
            leanMassKg: lean)
        return RMRResolver.resolve(biometrics: bio, measuredRMR: measured)
    }

    static func tdee(rmr: Double) -> Double { rmr * pal }

    static func sourceLabel(_ source: RMRSource) -> String {
        switch source {
        case .dexaMeasured: return "from DEXA"
        case .katchMcArdle: return "Katch-McArdle (DEXA lean mass)"
        case .mifflinStJeor: return "Mifflin-St Jeor"
        }
    }
}

extension Profile {
    var calorieTarget: CalorieTarget {
        calorieModeRaw == "fixed" ? .fixed(calorieFixed) : .tdeeOffset(calorieOffset)
    }

    var macroSplit: MacroSplit {
        switch macroPresetRaw {
        case "highProtein": return .highProtein
        case "keto": return .keto
        case "custom": return .custom(carbPct: customCarbPct, fatPct: customFatPct)
        default: return .default
        }
    }

    var unitSystem: UnitSystem { UnitSystem(rawValue: unitSystemRaw) ?? .metric }
}
