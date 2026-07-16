import SwiftUI
import CoffeeBeanCore

struct MacrosCard: View {
    let consumed: Macros
    let target: Macros

    var body: some View {
        Card {
            HStack(spacing: 14) {
                column("Carbs", consumed.carbG, target.carbG, Theme.carbs)
                column("Fat", consumed.fatG, target.fatG, Theme.fat)
                column("Protein", consumed.proteinG, target.proteinG, Theme.protein)
            }
        }
    }

    private func column(_ name: String, _ have: Double, _ goal: Double, _ color: Color) -> some View {
        VStack(spacing: 6) {
            Text(name).font(.subheadline).bold().foregroundStyle(Theme.textPrimary)
            Text("\(have.grouped) g / \(goal.grouped)")
                .font(.caption).monospacedDigit().foregroundStyle(Theme.textSecondary)
            ProgressBar(fraction: goal > 0 ? have / goal : 0, color: color, height: 7)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(name) \(Int(have)) of \(Int(goal)) grams")
    }
}
