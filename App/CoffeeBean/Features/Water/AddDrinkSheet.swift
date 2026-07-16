import SwiftUI

/// Log a custom drink: pick a type and volume (±50 ml).
struct AddDrinkSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var type = "Water"
    @State private var volumeMl: Double = 250
    /// (displayName, volumeMl, drinkTypeRaw)
    let onSave: (String, Double, String) -> Void

    private let types = ["Water", "Coffee", "Tea", "Protein Shake", "Juice"]

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
                    Text("\(Int(volumeMl)) ml")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.water)
                    HStack(spacing: 28) {
                        roundStep("minus") { volumeMl = max(50, volumeMl - 50) }
                        roundStep("plus") { volumeMl = min(2000, volumeMl + 50) }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Add a Drink")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Log") { onSave(type, volumeMl, type.lowercased()); dismiss() }.bold()
                }
            }
        }
        .presentationDetents([.height(300)])
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
