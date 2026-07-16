import SwiftUI
import CoffeeBeanCore

/// Quick morning weigh-in entry — steps ±0.1 kg (metric) / ±0.2 lb (imperial),
/// stored canonically in kg.
struct LogWeightSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var displayValue: Double
    private let system: UnitSystem
    private let onSaveKg: (Double) -> Void

    private var step: Double { system == .metric ? 0.1 : 0.2 }
    private var unitLabel: String { system == .metric ? "kg" : "lb" }
    private var range: ClosedRange<Double> { system == .metric ? 30...300 : 66...660 }

    init(initialKg: Double, system: UnitSystem, onSaveKg: @escaping (Double) -> Void) {
        self.system = system
        self.onSaveKg = onSaveKg
        let display = Quantity(canonicalValue: initialKg, kind: .bodyMass).value(in: system)
        _displayValue = State(initialValue: (display * 10).rounded() / 10)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.sheet.ignoresSafeArea()
                VStack(spacing: 28) {
                    Text(String(format: "%.1f %@", displayValue, unitLabel))
                        .font(.system(size: 46, weight: .bold, design: .rounded)).monospacedDigit()
                        .foregroundStyle(Theme.accent)
                    HStack(spacing: 28) {
                        roundStep("minus", "Decrease weight") { adjust(-step) }
                        roundStep("plus", "Increase weight") { adjust(step) }
                    }
                    Text("morning, post-void, fasted")
                        .font(.caption).foregroundStyle(Theme.textSecondary)
                }
                .padding()
            }
            .navigationTitle("Log weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.bold()
                }
            }
        }
        .presentationDetents([.height(320)])
    }

    private func adjust(_ delta: Double) {
        let next = ((displayValue + delta) * 10).rounded() / 10
        displayValue = min(range.upperBound, max(range.lowerBound, next))
    }

    private func save() {
        if let q = Quantity(displayValue: displayValue, kind: .bodyMass, system: system) {
            onSaveKg(q.canonicalValue)
        }
        dismiss()
    }

    private func roundStep(_ symbol: String, _ label: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.title2)
                .frame(width: 60, height: 60)
                .background(Theme.card, in: Circle())
                .foregroundStyle(Theme.textPrimary)
        }
        .accessibilityLabel(label)
    }
}
