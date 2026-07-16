import SwiftUI
import CoffeeBeanCore

/// Waist measurement entry — steps ±0.5 cm (metric) / ±0.25 in (imperial), stored in cm.
struct LogWaistSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var displayValue: Double
    private let system: UnitSystem
    private let onSaveCm: (Double) -> Void

    private var step: Double { system == .metric ? 0.5 : 0.25 }
    private var unitLabel: String { system == .metric ? "cm" : "in" }
    private var range: ClosedRange<Double> { system == .metric ? 40...200 : 16...80 }

    init(initialCm: Double, system: UnitSystem, onSaveCm: @escaping (Double) -> Void) {
        self.system = system
        self.onSaveCm = onSaveCm
        let display = Quantity(canonicalValue: initialCm, kind: .height).value(in: system)
        _displayValue = State(initialValue: (display * 4).rounded() / 4)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.sheet.ignoresSafeArea()
                VStack(spacing: 28) {
                    Text(String(format: system == .metric ? "%.1f %@" : "%.2f %@", displayValue, unitLabel))
                        .font(.system(size: 46, weight: .bold, design: .rounded)).monospacedDigit()
                        .foregroundStyle(Theme.protein)
                    HStack(spacing: 28) {
                        roundStep("minus", "Decrease waist") { adjust(-step) }
                        roundStep("plus", "Increase waist") { adjust(step) }
                    }
                    Text("morning, relaxed")
                        .font(.caption).foregroundStyle(Theme.textSecondary)
                }
                .padding()
            }
            .navigationTitle("Log waist")
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
        let next = ((displayValue + delta) * 4).rounded() / 4
        displayValue = min(range.upperBound, max(range.lowerBound, next))
    }

    private func save() {
        if let q = Quantity(displayValue: displayValue, kind: .height, system: system) {
            onSaveCm(q.canonicalValue)
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
