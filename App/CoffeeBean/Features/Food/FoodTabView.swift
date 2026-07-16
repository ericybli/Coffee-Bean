import SwiftUI
import CoffeeBeanCore

/// Food (home) tab. Placeholder body that also proves the CoffeeBeanCore
/// engine is linked and running by computing a sample TDEE.
struct FoodTabView: View {
    private var sampleTDEE: Int {
        let bio = Biometrics(weightKg: 80, heightCm: 180, ageYears: 30, sex: .male,
                             bodyFatFraction: nil, leanMassKg: nil)
        let rmr = RMRResolver.resolve(biometrics: bio, measuredRMR: nil).value
        let tdee = EnergyBalance.staticTDEE(rmr: rmr, activeEnergyKcal: 500,
                                            intakeKcal: 2500, macros: nil, tefMode: .flatTen)
        return Int(tdee.rounded())
    }

    var body: some View {
        ScreenScaffold(title: "Food") {
            VStack(spacing: 8) {
                Text("Energy engine online")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                Text("\(sampleTDEE)")
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.accent)
                Text("sample TDEE (kcal) · via CoffeeBeanCore")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }
}
