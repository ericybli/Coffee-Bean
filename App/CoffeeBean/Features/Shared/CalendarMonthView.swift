import SwiftUI

/// Design §1 calendar: month grid with amber selection, small amber dots under logged
/// days, ‹ › month nav (capped at +4 weeks ahead), and a Back-to-today link.
struct CalendarMonthView: View {
    let nav: DateNav
    let loggedDays: Set<Date>
    let onPick: (Date) -> Void

    @State private var displayedMonth: Date

    private let cal = Calendar.current

    init(nav: DateNav, loggedDays: Set<Date>, onPick: @escaping (Date) -> Void) {
        self.nav = nav
        self.loggedDays = loggedDays
        self.onPick = onPick
        let start = Calendar.current.dateInterval(of: .month, for: nav.selectedDay)?.start ?? nav.selectedDay
        _displayedMonth = State(initialValue: start)
    }

    var body: some View {
        VStack(spacing: 14) {
            header
            weekdayHeader
            monthGrid
            Button("Back to today") {
                nav.backToToday()
                onPick(nav.today)
            }
            .font(.subheadline).tint(Theme.accent)
        }
        .padding()
    }

    // MARK: - Pieces

    private var header: some View {
        HStack {
            Button { shiftMonth(-1) } label: { Image(systemName: "chevron.left") }
                .accessibilityLabel("Previous month")
            Spacer()
            Text(displayedMonth.formatted(.dateTime.month(.wide).year()))
                .font(.headline).foregroundStyle(Theme.textPrimary)
            Spacer()
            Button { shiftMonth(1) } label: { Image(systemName: "chevron.right") }
                .disabled(!canGoForward)
                .accessibilityLabel("Next month")
        }
        .tint(Theme.accent)
        .padding(.horizontal, 4)
    }

    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(weekdaySymbols, id: \.self) { s in
                Text(s).font(.caption2).foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var monthGrid: some View {
        let days = monthDays()
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 6) {
            ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                if let day {
                    dayCell(day)
                } else {
                    Color.clear.frame(height: 40)
                }
            }
        }
    }

    private func dayCell(_ day: Date) -> some View {
        let isSelected = cal.isDate(day, inSameDayAs: nav.selectedDay)
        let isToday = cal.isDateInToday(day)
        let isLogged = loggedDays.contains(cal.startOfDay(for: day))
        let selectable = day <= nav.maxDay

        return Button {
            nav.select(day)
            onPick(day)
        } label: {
            VStack(spacing: 2) {
                Text("\(cal.component(.day, from: day))")
                    .font(.subheadline).monospacedDigit()
                    .fontWeight(isToday ? .bold : .regular)
                    .foregroundStyle(isSelected ? Color(hex: 0x26190A) : Theme.textPrimary)
                    .frame(width: 32, height: 32)
                    .background(isSelected ? Theme.accent : .clear, in: Circle())
                    .overlay {
                        if isToday && !isSelected {
                            Circle().strokeBorder(Theme.accent, lineWidth: 1.5)
                        }
                    }
                Circle().fill(isLogged ? Theme.accent : .clear).frame(width: 4, height: 4)
            }
            .opacity(selectable ? 1 : 0.3)
        }
        .buttonStyle(.plain)
        .disabled(!selectable)
        .accessibilityLabel(day.formatted(.dateTime.weekday(.wide).month().day()))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Calendar math

    /// The displayed month as a 7-column grid: leading nils pad to the first weekday.
    private func monthDays() -> [Date?] {
        guard let interval = cal.dateInterval(of: .month, for: displayedMonth),
              let dayCount = cal.range(of: .day, in: .month, for: displayedMonth)?.count else {
            return []
        }
        let firstWeekday = cal.component(.weekday, from: interval.start)
        let leading = (firstWeekday - cal.firstWeekday + 7) % 7
        var cells: [Date?] = Array(repeating: nil, count: leading)
        for offset in 0..<dayCount {
            cells.append(cal.date(byAdding: .day, value: offset, to: interval.start))
        }
        return cells
    }

    private var weekdaySymbols: [String] {
        let symbols = cal.veryShortWeekdaySymbols   // ordered Sunday-first
        let shift = cal.firstWeekday - 1
        return Array(symbols[shift...] + symbols[..<shift])
    }

    private var canGoForward: Bool {
        guard let next = cal.date(byAdding: .month, value: 1, to: displayedMonth) else { return false }
        return next <= nav.maxDay
    }

    private func shiftMonth(_ delta: Int) {
        if let d = cal.date(byAdding: .month, value: delta, to: displayedMonth) {
            displayedMonth = d
        }
    }
}
