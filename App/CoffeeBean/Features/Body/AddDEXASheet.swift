import SwiftUI

/// Enter a DEXA scan's metrics and optionally mark its RMR authoritative.
struct AddDEXASheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var bodyFatPct: Double = 14.0
    @State private var leanKg: Double = 59.0
    @State private var rmr: Double = 1700
    @State private var authoritative = true
    let onSave: (BodyScan) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Stepper(value: $bodyFatPct, in: 3...60, step: 0.1) {
                    row("Body fat", String(format: "%.1f%%", bodyFatPct))
                }
                Stepper(value: $leanKg, in: 20...120, step: 0.1) {
                    row("Lean mass", String(format: "%.1f kg", leanKg))
                }
                Stepper(value: $rmr, in: 800...3000, step: 10) {
                    row("RMR", String(format: "%.0f kcal", rmr))
                }
                Toggle("Use this RMR as authoritative", isOn: $authoritative)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.sheet)
            .navigationTitle("Add DEXA")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(BodyScan(date: Date(), bodyFatFraction: bodyFatPct / 100,
                                        leanMassKg: leanKg, fatMassKg: nil, rmrKcal: rmr,
                                        isRMRAuthoritative: authoritative))
                        dismiss()
                    }.bold()
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(Theme.textPrimary)
            Spacer()
            Text(value).foregroundStyle(Theme.textSecondary)
        }
    }
}
