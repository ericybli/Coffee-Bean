import SwiftUI
import CoffeeBeanCore

/// Blue progress ring: percent + amount consumed vs the daily goal.
struct WaterRing: View {
    let consumedMl: Double
    let goalMl: Double
    let system: UnitSystem

    private var fraction: Double { goalMl > 0 ? min(consumedMl / goalMl, 1) : 0 }
    private var percent: Int { goalMl > 0 ? Int((consumedMl / goalMl * 100).rounded()) : 0 }

    var body: some View {
        ZStack {
            Circle().stroke(Theme.water.opacity(0.15), lineWidth: 15)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(Theme.water, style: StrokeStyle(lineWidth: 15, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.35), value: fraction)
            VStack(spacing: 4) {
                Text("\(percent)%")
                    .font(.system(size: 34, weight: .heavy, design: .rounded)).monospacedDigit()
                    .foregroundStyle(Theme.textPrimary)
                Text(Units.volume(consumedMl, system))
                    .font(.headline).monospacedDigit().foregroundStyle(Theme.water)
                Text(Units.volumeGoal(goalMl, system))
                    .font(.caption).foregroundStyle(Theme.textSecondary)
            }
        }
        .frame(width: 180, height: 180)
        .accessibilityElement()
        .accessibilityLabel("Water: \(percent) percent of daily goal, \(Units.volume(consumedMl, system))")
    }
}
