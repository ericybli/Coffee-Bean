import SwiftUI

/// Design §1 week strip: 7 day cells, prev/next week controls with the range label,
/// swipe to change week. Logged days fill amber; today gets a floating dot above;
/// a selected non-today day gets a halo ring.
struct WeekStrip: View {
    let nav: DateNav
    let loggedDays: Set<Date>

    private let cal = Calendar.current

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Button("‹ Prev week") { nav.shiftWeek(-1) }
                Spacer()
                Text(nav.weekRangeLabel).font(.caption).foregroundStyle(Theme.textSecondary)
                Spacer()
                Button("Next week ›") { nav.shiftWeek(1) }
            }
            .font(.caption)
            .tint(Theme.accent)

            HStack(spacing: 0) {
                ForEach(nav.weekDays, id: \.self) { day in
                    dayCell(day).frame(maxWidth: .infinity)
                }
            }
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 25).onEnded { value in
                if value.translation.width < -45 { nav.shiftWeek(1) }
                else if value.translation.width > 45 { nav.shiftWeek(-1) }
            }
        )
    }

    private func dayCell(_ day: Date) -> some View {
        let isSelected = cal.isDate(day, inSameDayAs: nav.selectedDay)
        let isToday = cal.isDateInToday(day)
        let isLogged = loggedDays.contains(cal.startOfDay(for: day))
        let selectable = day <= nav.maxDay

        return Button { nav.select(day) } label: {
            VStack(spacing: 3) {
                // 4pt today marker floats above the letter without shifting alignment.
                Circle().fill(isToday ? Theme.accent : .clear).frame(width: 4, height: 4)
                Text(weekdayLetter(day))
                    .font(.caption2).foregroundStyle(Theme.textSecondary)
                ZStack {
                    if isLogged {
                        Circle().fill(Theme.accent)
                    } else {
                        Circle().strokeBorder(Theme.textSecondary.opacity(0.35), lineWidth: 1.5)
                    }
                    Text("\(cal.component(.day, from: day))")
                        .font(.caption).bold().monospacedDigit()
                        .foregroundStyle(isLogged ? Color(hex: 0x26190A) : Theme.textPrimary)
                }
                .frame(width: 30, height: 30)
                .overlay {
                    if isSelected && !isToday {
                        Circle().strokeBorder(Theme.accent.opacity(0.6), lineWidth: 2.5)
                            .frame(width: 38, height: 38)
                    } else if isSelected {
                        Circle().strokeBorder(Theme.accent, lineWidth: 2)
                            .frame(width: 36, height: 36)
                    }
                }
            }
            .opacity(selectable ? 1 : 0.3)
        }
        .buttonStyle(.plain)
        .disabled(!selectable)
        .accessibilityLabel(day.formatted(.dateTime.weekday(.wide).month().day()))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func weekdayLetter(_ day: Date) -> String {
        String(day.formatted(.dateTime.weekday(.narrow)))
    }
}
