import SwiftUI
import SwiftData
import CoffeeBeanCore

/// Adjust each preset's size (±50 ml canonical; display follows units). Changes apply live.
struct EditPresetsSheet: View {
    @Environment(\.dismiss) private var dismiss
    let presets: [DrinkPreset]
    var system: UnitSystem = .metric

    var body: some View {
        NavigationStack {
            Form {
                ForEach(presets) { preset in
                    Stepper(value: binding(preset), in: 50...2000, step: 50) {
                        HStack {
                            Image(systemName: preset.iconName).foregroundStyle(Theme.water)
                            Text(preset.label).foregroundStyle(Theme.textPrimary)
                            Spacer()
                            Text(Units.volume(preset.volumeMl, system)).foregroundStyle(Theme.textSecondary)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.sheet)
            .navigationTitle("Edit Presets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
        .presentationDetents([.medium])
    }

    private func binding(_ preset: DrinkPreset) -> Binding<Double> {
        Binding(get: { preset.volumeMl }, set: { preset.volumeMl = $0 })
    }
}
