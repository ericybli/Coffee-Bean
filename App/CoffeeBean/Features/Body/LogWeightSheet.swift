import SwiftUI

/// Quick morning weigh-in entry (±0.1 kg).
struct LogWeightSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var kg: Double
    let onSave: (Double) -> Void

    init(initial: Double = 72, onSave: @escaping (Double) -> Void) {
        _kg = State(initialValue: (initial * 10).rounded() / 10)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.sheet.ignoresSafeArea()
                VStack(spacing: 28) {
                    Text(String(format: "%.1f kg", kg))
                        .font(.system(size: 46, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.accent)
                    HStack(spacing: 28) {
                        roundStep("minus") { kg = clamp(kg - 0.1) }
                        roundStep("plus") { kg = clamp(kg + 0.1) }
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
                    Button("Save") { onSave(kg); dismiss() }.bold()
                }
            }
        }
        .presentationDetents([.height(320)])
    }

    private func clamp(_ v: Double) -> Double { min(300, max(30, (v * 10).rounded() / 10)) }

    private func roundStep(_ symbol: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.title2)
                .frame(width: 60, height: 60)
                .background(Theme.card, in: Circle())
                .foregroundStyle(Theme.textPrimary)
        }
    }
}
