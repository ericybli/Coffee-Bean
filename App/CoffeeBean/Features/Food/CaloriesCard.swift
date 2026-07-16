import SwiftUI

struct CaloriesCard: View {
    let consumed: Double
    let target: Double
    let tdee: Double

    private var remaining: Double { target - consumed }
    private var fraction: Double { target > 0 ? consumed / target : 0 }
    private var surplus: Double { consumed - tdee }

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                Text("Calories").font(.headline).foregroundStyle(Theme.textPrimary)
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(consumed.grouped)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .monospacedDigit().lineLimit(1).minimumScaleFactor(0.6)
                        .foregroundStyle(Theme.textPrimary)
                    Text("/ \(target.grouped) cal").foregroundStyle(Theme.textSecondary)
                    Spacer()
                    Text(remaining >= 0 ? "\(remaining.grouped) left" : "\((-remaining).grouped) over")
                        .font(.subheadline).monospacedDigit()
                        .foregroundStyle(remaining >= 0 ? Theme.textSecondary : Theme.negative)
                }
                ProgressBar(fraction: fraction, color: Theme.accent)
                Text(caption).font(.caption).foregroundStyle(Theme.textSecondary)
            }
            .accessibilityElement(children: .combine)
        }
    }

    private var caption: String {
        let s = surplus >= 0 ? "+\(surplus.grouped) kcal surplus" : "\((-surplus).grouped) kcal deficit"
        return "TDEE \(tdee.grouped) (est.) · \(s)"
    }
}
