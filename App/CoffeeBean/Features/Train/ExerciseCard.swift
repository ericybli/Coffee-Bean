import SwiftUI
import CoffeeBeanCore

/// One exercise in the day's session: last-time comparison + SET | KG/LB | REPS rows with
/// steppers. Weights are stored in kg; imperial mode displays lb (nearest 0.5) and steps
/// ±5 lb, converting back to canonical kg.
struct ExerciseCard: View {
    let name: String
    let sets: [WorkoutSet]             // the day's sets for this exercise, ordered by setIndex
    let previous: [WorkoutSet]         // last earlier day's sets for this exercise (may be empty)
    var system: UnitSystem = .metric
    let onAddSet: () -> Void
    let onDeleteSet: (WorkoutSet) -> Void
    let onRemoveExercise: () -> Void

    private static let kgPerLb = 0.45359237
    private var unitLabel: String { system == .metric ? "kg" : "lb" }

    private var volume: Double { sets.reduce(0) { $0 + $1.volumeKg } }
    private var previousVolume: Double { previous.reduce(0) { $0 + $1.volumeKg } }

    /// Displayed weight for a canonical kg value (lb snapped to nearest 0.5 in imperial).
    private func displayWeight(_ kg: Double) -> Double {
        system == .metric ? kg : (kg / Self.kgPerLb * 2).rounded() / 2
    }

    /// Step a canonical kg weight by ±2.5 kg (metric) or ±5 lb (imperial, snapped).
    private func stepped(_ kg: Double, up: Bool) -> Double {
        if system == .metric {
            return max(0, min(500, kg + (up ? 2.5 : -2.5)))
        }
        let lb = displayWeight(kg) + (up ? 5 : -5)
        return max(0, min(1100, lb)) * Self.kgPerLb
    }

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(name).font(.headline).foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Button(action: onRemoveExercise) {
                        Image(systemName: "xmark").font(.caption)
                            .frame(width: 44, height: 44).contentShape(Rectangle())
                    }
                    .buttonStyle(.plain).foregroundStyle(Theme.textSecondary)
                    .accessibilityLabel("Remove \(name)")
                }

                if let first = previous.first {
                    let delta = volume - previousVolume
                    HStack {
                        Text("Last time \(displayWeight(first.weightKg).cleanKg) \(unitLabel) × \(first.reps) × \(previous.count)")
                            .font(.caption).foregroundStyle(Theme.textSecondary)
                        Spacer()
                        if previousVolume > 0 {
                            Text(String(format: "%+.0f %@ vol",
                                        system == .metric ? delta : delta / Self.kgPerLb, unitLabel))
                                .font(.caption).monospacedDigit()
                                .foregroundStyle(delta >= 0 ? Theme.positive : Theme.negative)
                        }
                    }
                }

                HStack {
                    Text("SET").frame(width: 40, alignment: .leading)
                    Spacer()
                    Text(unitLabel.uppercased()).frame(width: 110)
                    Text("REPS").frame(width: 96)
                    Color.clear.frame(width: 32)
                }
                .font(.caption2).foregroundStyle(Theme.textSecondary)

                ForEach(sets) { set in setRow(set) }

                Button(action: onAddSet) {
                    Label("Add set", systemImage: "plus").font(.subheadline).frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered).tint(Theme.accent)
            }
        }
    }

    private func setRow(_ set: WorkoutSet) -> some View {
        HStack {
            Text("\(set.setIndex + 1)").font(.subheadline).monospacedDigit()
                .foregroundStyle(Theme.textSecondary).frame(width: 40, alignment: .leading)
            Spacer()
            stepGroup(value: displayWeight(set.weightKg).cleanKg, width: 110,
                      minusLabel: "Decrease weight", plusLabel: "Increase weight",
                      minus: { set.weightKg = stepped(set.weightKg, up: false) },
                      plus: { set.weightKg = stepped(set.weightKg, up: true) })
            stepGroup(value: "\(set.reps)", width: 96,
                      minusLabel: "Decrease reps", plusLabel: "Increase reps",
                      minus: { set.reps = max(1, set.reps - 1) },
                      plus: { set.reps = min(50, set.reps + 1) })
            Button { onDeleteSet(set) } label: {
                Image(systemName: "xmark").font(.caption2)
                    .frame(width: 32, height: 44).contentShape(Rectangle())
            }
            .buttonStyle(.plain).foregroundStyle(Theme.negative)
            .accessibilityLabel("Delete set \(set.setIndex + 1)")
        }
    }

    private func stepGroup(value: String, width: CGFloat, minusLabel: String, plusLabel: String,
                           minus: @escaping () -> Void, plus: @escaping () -> Void) -> some View {
        HStack(spacing: 4) {
            miniStep("minus", minusLabel, minus)
            Text(value).font(.subheadline).bold().monospacedDigit()
                .foregroundStyle(Theme.textPrimary).frame(minWidth: 34)
            miniStep("plus", plusLabel, plus)
        }
        .frame(width: width)
    }

    private func miniStep(_ symbol: String, _ label: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol).font(.caption2)
                .frame(width: 26, height: 26)
                .background(Theme.background, in: Circle())
                .foregroundStyle(Theme.textPrimary)
                .frame(width: 30, height: 44).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

extension Double {
    /// "100" or "22.5" — no trailing .0 for whole kg values.
    var cleanKg: String {
        self == rounded() ? String(Int(self)) : String(format: "%.1f", self)
    }
}
