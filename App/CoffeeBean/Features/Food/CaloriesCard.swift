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
                    Text("\(Int(consumed))")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                    Text("/ \(Int(target)) cal").foregroundStyle(Theme.textSecondary)
                    Spacer()
                    Text(remaining >= 0 ? "\(Int(remaining)) left" : "\(Int(-remaining)) over")
                        .font(.subheadline)
                        .foregroundStyle(remaining >= 0 ? Theme.textSecondary : Theme.negative)
                }
                ProgressBar(fraction: fraction, color: Theme.accent)
                Text(caption).font(.caption).foregroundStyle(Theme.textSecondary)
            }
        }
    }

    private var caption: String {
        let s = surplus >= 0 ? "+\(Int(surplus)) kcal surplus" : "\(Int(surplus)) kcal deficit"
        return "TDEE \(Int(tdee)) (est.) · \(s)"
    }
}
