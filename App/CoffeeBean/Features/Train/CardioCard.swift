import SwiftUI
import Charts

/// Cardio volume for the selected day + trailing-8-days bar chart + the day's session list.
struct CardioCard: View {
    let day: Date                      // startOfDay; the selected day
    let sessions: [CardioSession]      // all sessions, any day
    let onAdd: () -> Void
    let onDelete: (CardioSession) -> Void

    private var cal: Calendar { Calendar.current }
    private var daySessions: [CardioSession] { sessions.filter { cal.isDate($0.day, inSameDayAs: day) } }
    private var todayMinutes: Double { daySessions.reduce(0) { $0 + $1.minutes } }
    private var todayKcal: Double { daySessions.reduce(0) { $0 + kcal($1) } }

    /// Minutes on the most recent earlier day that had any cardio.
    private var lastCardioDayMinutes: Double? {
        let earlier = sessions.filter { $0.day < day }
        guard let lastDay = earlier.map(\.day).max() else { return nil }
        return earlier.filter { $0.day == lastDay }.reduce(0) { $0 + $1.minutes }
    }

    private var last8Days: [(date: Date, minutes: Double)] {
        (0..<8).reversed().map { back in
            let d = cal.date(byAdding: .day, value: -back, to: day)!
            let mins = sessions.filter { cal.isDate($0.day, inSameDayAs: d) }.reduce(0) { $0 + $1.minutes }
            return (d, mins)
        }
    }

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Cardio volume").font(.headline).foregroundStyle(Theme.textPrimary)

                HStack(alignment: .firstTextBaseline) {
                    Text("\(Int(todayMinutes)) min")
                        .font(.system(size: 32, weight: .bold, design: .rounded)).monospacedDigit()
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        if let last = lastCardioDayMinutes {
                            let delta = todayMinutes - last
                            Text(String(format: "%+d min", Int(delta)))
                                .font(.headline)
                                .foregroundStyle(delta >= 0 ? Theme.positive : Theme.negative)
                            Text("vs last cardio day").font(.caption2).foregroundStyle(Theme.textSecondary)
                        }
                    }
                }
                Text("~\(todayKcal.grouped) kcal burned")
                    .font(.caption).foregroundStyle(Theme.textSecondary)

                Chart(last8Days, id: \.date) { item in
                    BarMark(x: .value("Day", item.date, unit: .day), y: .value("Min", item.minutes))
                        .foregroundStyle(cal.isDate(item.date, inSameDayAs: day) ? Theme.protein : Theme.textSecondary.opacity(0.35))
                        .cornerRadius(3)
                }
                .chartXAxis { AxisMarks(values: .automatic(desiredCount: 4)) }
                .frame(height: 90)
                .accessibilityHidden(true)

                ForEach(daySessions) { s in sessionRow(s) }

                Button(action: onAdd) {
                    Label("Add cardio", systemImage: "plus").frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered).tint(Theme.protein)
            }
        }
    }

    private func sessionRow(_ s: CardioSession) -> some View {
        HStack {
            Text(CardioType(rawValue: s.typeRaw)?.title ?? s.typeRaw)
                .font(.subheadline).foregroundStyle(Theme.textPrimary)
            Spacer()
            Text("\(Int(s.minutes)) min · ~\(kcal(s).grouped) kcal")
                .font(.caption).monospacedDigit().foregroundStyle(Theme.textSecondary)
            Button { onDelete(s) } label: {
                Image(systemName: "xmark").font(.caption2)
                    .frame(width: 44, height: 44).contentShape(Rectangle())
            }
            .buttonStyle(.plain).foregroundStyle(Theme.negative)
            .accessibilityLabel("Delete \(CardioType(rawValue: s.typeRaw)?.title ?? s.typeRaw)")
        }
    }

    private func kcal(_ s: CardioSession) -> Double {
        (CardioType(rawValue: s.typeRaw)?.kcalPerMin ?? 8) * s.minutes
    }
}
