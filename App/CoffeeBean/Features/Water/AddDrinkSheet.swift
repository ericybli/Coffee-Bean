import SwiftUI
import CoffeeBeanCore

/// Log a custom drink: pick a type and volume (±50 ml canonical; display follows units).
struct AddDrinkSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var type = "Water"
    @State private var volumeMl: Double = 250
    @State private var caffeineMg: Double = 0
    var system: UnitSystem = .metric
    /// (displayName, volumeMl, drinkTypeRaw, caffeineMg)
    let onSave: (String, Double, String, Double) -> Void

    private let types = ["Water", "Coffee", "Tea", "Protein Shake", "Juice"]
    /// Typical caffeine per drink, editable before logging.
    private let defaultCaffeine: [String: Double] = ["Coffee": 95, "Tea": 45]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.sheet.ignoresSafeArea()
                VStack(spacing: 24) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(types, id: \.self) { t in
                                Text(t)
                                    .font(.subheadline)
                                    .padding(.horizontal, 14).padding(.vertical, 8)
                                    .background(t == type ? Theme.water : Theme.card, in: Capsule())
                                    .foregroundStyle(t == type ? Color(hex: 0x0A1826) : Theme.textPrimary)
                                    .onTapGesture { type = t }
                            }
                        }
                        .padding(.horizontal)
                    }
                    Text(Units.volume(volumeMl, system))
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.water)
                    HStack(spacing: 28) {
                        roundStep("minus") { volumeMl = max(50, volumeMl - 50) }
                        roundStep("plus") { volumeMl = min(2000, volumeMl + 50) }
                    }
                    Stepper(value: $caffeineMg, in: 0...500, step: 5) {
                        HStack {
                            Image(systemName: "bolt.fill").font(.caption).foregroundStyle(Theme.accent)
                            Text("Caffeine \(Int(caffeineMg)) mg")
                                .foregroundStyle(Theme.textPrimary).monospacedDigit()
                        }
                    }
                    .padding(.horizontal, 32)
                }
                .padding(.vertical)
            }
            .navigationTitle("Add a Drink")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Log") { onSave(type, volumeMl, type.lowercased(), caffeineMg); dismiss() }.bold()
                }
            }
            .onChange(of: type) { caffeineMg = defaultCaffeine[type] ?? 0 }
        }
        .presentationDetents([.height(340)])
    }

    private func roundStep(_ symbol: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol).font(.title2)
                .frame(width: 56, height: 56)
                .background(Theme.card, in: Circle())
                .foregroundStyle(Theme.textPrimary)
        }
    }
}
