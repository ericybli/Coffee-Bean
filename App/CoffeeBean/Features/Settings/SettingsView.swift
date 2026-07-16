import SwiftUI
import SwiftData
import CoffeeBeanCore

/// Settings: units, profile, daily targets (design §6–7).
struct SettingsView: View {
    @Query private var profiles: [Profile]
    @Query(sort: \BodyScan.date, order: .reverse) private var scans: [BodyScan]
    @Query(sort: \WeightEntry.date, order: .reverse) private var weights: [WeightEntry]

    var body: some View {
        Group {
            if let profile = profiles.first {
                SettingsForm(profile: profile, scans: scans, latestWeightKg: weights.first?.massKg)
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct SettingsForm: View {
    @Bindable var profile: Profile
    let scans: [BodyScan]
    let latestWeightKg: Double?

    private var system: UnitSystem { profile.unitSystem }
    private var rmrResult: RMRResult {
        EnergyResolver.rmr(profile: profile, scans: scans, latestWeightKg: latestWeightKg)
    }
    private var tdee: Double { EnergyResolver.tdee(rmr: rmrResult.value) }
    private var calorieTarget: Double { profile.calorieTarget.resolve(tdee: tdee) }

    var body: some View {
        Form {
            Section("Units") {
                Picker("Units", selection: $profile.unitSystemRaw) {
                    Text("Metric").tag("metric")
                    Text("Imperial").tag("imperial")
                }
                .pickerStyle(.segmented)
                Text("All displays switch units — data is always stored metric.")
                    .font(.caption2).foregroundStyle(Theme.textSecondary)
            }

            Section("Profile") {
                Picker("Sex", selection: $profile.sexRaw) {
                    Text("Male").tag("male")
                    Text("Female").tag("female")
                }
                .pickerStyle(.segmented)
                Stepper(value: $profile.age, in: 13...100) { row("Age", "\(profile.age)") }
                heightRow
            }

            Section("Daily targets") {
                Picker("Calories", selection: $profile.calorieModeRaw) {
                    Text("Fixed value").tag("fixed")
                    Text("vs TDEE (±)").tag("tdeeOffset")
                }
                .pickerStyle(.segmented)

                if profile.calorieModeRaw == "fixed" {
                    Stepper(value: $profile.calorieFixed, in: 1200...6000, step: 50) {
                        row("Target", "\(profile.calorieFixed.grouped) kcal")
                    }
                } else {
                    Stepper(value: $profile.calorieOffset, in: -1000...1000, step: 50) {
                        row(offsetLabel, String(format: "%+d kcal", Int(profile.calorieOffset)))
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("= \(calorieTarget.grouped) kcal target · TDEE \(tdee.grouped) (est.)")
                        .font(.subheadline).monospacedDigit().foregroundStyle(Theme.textPrimary)
                    Text("RMR \(rmrResult.value.grouped) kcal · \(EnergyResolver.sourceLabel(rmrResult.source))")
                        .font(.caption2).foregroundStyle(Theme.textSecondary)
                }

                Picker("Macro split", selection: $profile.macroPresetRaw) {
                    Text("Default 50/30/20").tag("default")
                    Text("High Protein 40/20/40").tag("highProtein")
                    Text("Keto 10/65/25").tag("keto")
                    Text("Custom").tag("custom")
                }

                if profile.macroPresetRaw == "custom" {
                    Stepper(value: $profile.customCarbPct, in: 0...80, step: 5) {
                        row("Carbs", "\(Int(profile.customCarbPct))%")
                    }
                    Stepper(value: $profile.customFatPct, in: 0...80, step: 5) {
                        row("Fat", "\(Int(profile.customFatPct))%")
                    }
                    Text("Protein auto-fills the remainder: \(Int(profile.macroSplit.proteinPct))%")
                        .font(.caption2).foregroundStyle(Theme.textSecondary)
                }

                ratioBar
            }

            Section("App") {
                Stepper(value: $profile.waterGoalMl, in: 500...6000, step: 250) {
                    row("Water goal", Units.volume(profile.waterGoalMl, system))
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background)
    }

    // MARK: - Rows

    private var offsetLabel: String {
        profile.calorieOffset >= 0 ? "Surplus over TDEE" : "Deficit under TDEE"
    }

    @ViewBuilder private var heightRow: some View {
        if system == .metric {
            Stepper(value: $profile.heightCm, in: 120...220, step: 1) {
                row("Height", Units.height(profile.heightCm, system))
            }
        } else {
            Stepper(
                value: Binding(
                    get: { Quantity(canonicalValue: profile.heightCm, kind: .height).value(in: .imperial) },
                    set: { inches in
                        if let q = Quantity(displayValue: inches, kind: .height, system: .imperial) {
                            profile.heightCm = q.canonicalValue
                        }
                    }),
                in: 48...90, step: 1
            ) {
                row("Height", Units.height(profile.heightCm, system))
            }
        }
    }

    private var ratioBar: some View {
        let split = profile.macroSplit
        return GeometryReader { geo in
            HStack(spacing: 2) {
                Rectangle().fill(Theme.carbs).frame(width: geo.size.width * split.carbPct / 100)
                Rectangle().fill(Theme.fat).frame(width: geo.size.width * split.fatPct / 100)
                Rectangle().fill(Theme.protein)
            }
            .clipShape(Capsule())
        }
        .frame(height: 10)
        .accessibilityElement()
        .accessibilityLabel("Macro split: carbs \(Int(split.carbPct)), fat \(Int(split.fatPct)), protein \(Int(split.proteinPct)) percent")
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(Theme.textPrimary)
            Spacer()
            Text(value).monospacedDigit().foregroundStyle(Theme.textSecondary)
        }
    }
}
