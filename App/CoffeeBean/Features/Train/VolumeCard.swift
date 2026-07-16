import SwiftUI
import Charts
import CoffeeBeanCore

/// Session volume + delta vs the last same-routine day + bar chart of recent same-routine sessions.
struct VolumeCard: View {
    let routine: Routine
    let todayVolumeKg: Double
    /// Volumes of past same-routine sessions, oldest→newest, ending with today.
    let history: [(date: Date, volumeKg: Double)]
    var system: UnitSystem = .metric

    private static let kgPerLb = 0.45359237
    private var unitLabel: String { system == .metric ? "kg" : "lb" }
    private func display(_ kg: Double) -> Double { system == .metric ? kg : kg / Self.kgPerLb }

    private var lastVolume: Double? {
        history.count >= 2 ? history[history.count - 2].volumeKg : nil
    }

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Session volume").font(.headline).foregroundStyle(Theme.textPrimary)
                HStack(alignment: .firstTextBaseline) {
                    Text("\(display(todayVolumeKg).grouped) \(unitLabel)")
                        .font(.system(size: 32, weight: .bold, design: .rounded)).monospacedDigit()
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    if let last = lastVolume, last > 0 {
                        let delta = todayVolumeKg - last
                        let pct = delta / last * 100
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(String(format: "%+.0f %@ · %+.0f%%", display(delta), unitLabel, pct))
                                .font(.headline).monospacedDigit()
                                .foregroundStyle(delta >= 0 ? Theme.positive : Theme.negative)
                            Text("vs last \(routine.dayTitle)").font(.caption2).foregroundStyle(Theme.textSecondary)
                        }
                    }
                }
                if history.count >= 2 {
                    Chart(Array(history.enumerated()), id: \.offset) { idx, item in
                        BarMark(x: .value("Session", idx), y: .value("Volume", display(item.volumeKg)))
                            .foregroundStyle(idx == history.count - 1 ? Theme.accent : Theme.textSecondary.opacity(0.35))
                            .cornerRadius(3)
                    }
                    .chartXAxis(.hidden)
                    .frame(height: 80)
                    .accessibilityHidden(true)
                    Text("last \(history.count) \(routine.title.lowercased()) sessions")
                        .font(.caption2).foregroundStyle(Theme.textSecondary)
                }
            }
        }
    }
}
