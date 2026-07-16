import Foundation

public enum BMR {
    /// Mifflin-St Jeor resting metabolic rate (kcal/day).
    public static func mifflinStJeor(_ b: Biometrics) -> Double {
        let base = 10 * b.weightKg + 6.25 * b.heightCm - 5 * Double(b.ageYears)
        return base + (b.sex == .male ? 5 : -161)
    }

    /// Katch-McArdle resting metabolic rate (kcal/day) from lean body mass.
    public static func katchMcArdle(leanMassKg: Double) -> Double {
        370 + 21.6 * leanMassKg
    }
}
