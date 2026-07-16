import SwiftUI

/// Log cardio: pick a type, set minutes (±5) with a live kcal preview.
struct AddCardioSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var type: CardioType = .run
    @State private var minutes: Double = 20
    let onSave: (CardioType, Double) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.sheet.ignoresSafeArea()
                VStack(spacing: 24) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(CardioType.allCases) { t in
                                Text("\(t.title) \(Int(t.kcalPerMin))")
                                    .font(.subheadline)
                                    .padding(.horizontal, 14).padding(.vertical, 8)
                                    .background(t == type ? Theme.protein : Theme.card, in: Capsule())
                                    .foregroundStyle(t == type ? Color(hex: 0x0A2622) : Theme.textPrimary)
                                    .onTapGesture { type = t }
                            }
                        }
                        .padding(.horizontal)
                    }
                    Text("\(Int(minutes)) min")
                        .font(.system(size: 44, weight: .bold, design: .rounded)).monospacedDigit()
                        .foregroundStyle(Theme.protein)
                    Text("~\((type.kcalPerMin * minutes).grouped) kcal")
                        .font(.caption).foregroundStyle(Theme.textSecondary)
                    HStack(spacing: 28) {
                        step("minus", "Decrease minutes") { minutes = max(5, minutes - 5) }
                        step("plus", "Increase minutes") { minutes = min(240, minutes + 5) }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Add cardio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Log \(type.title) · \(Int(minutes)) min") { onSave(type, minutes); dismiss() }.bold()
                }
            }
        }
        .presentationDetents([.height(340)])
    }

    private func step(_ symbol: String, _ label: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol).font(.title2).frame(width: 56, height: 56)
                .background(Theme.card, in: Circle()).foregroundStyle(Theme.textPrimary)
        }
        .accessibilityLabel(label)
    }
}
