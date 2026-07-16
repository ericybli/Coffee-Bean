import Foundation
import SwiftData

/// Single-user profile (code-enforced singleton). All fields defaulted (CloudKit rules;
/// added fields lightweight-migrate).
@Model
final class Profile {
    var id: UUID = UUID()
    var heightCm: Double = 178
    var unitSystemRaw: String = "metric"
    var waterGoalMl: Double = 2000

    // Biometrics (drive Mifflin-St Jeor when no DEXA exists)
    var sexRaw: String = "male"
    var age: Int = 30

    // Daily targets (design §7)
    var calorieModeRaw: String = "tdeeOffset"   // "fixed" | "tdeeOffset"
    var calorieFixed: Double = 2600
    var calorieOffset: Double = 250
    var macroPresetRaw: String = "default"      // default | highProtein | keto | custom
    var customCarbPct: Double = 50
    var customFatPct: Double = 30

    init() {}
}
