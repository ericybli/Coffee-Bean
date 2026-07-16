import Foundation
import Observation

/// Shared selected-day state for the dated tabs (Food, Water, Train). Body always
/// shows the present and does not use this. Future selection is allowed up to
/// +4 weeks (training planning); past is unlimited (backfill).
@Observable
final class DateNav {
    private let cal = Calendar.current
    var selectedDay: Date

    init() {
        var day = Calendar.current.startOfDay(for: Date())
        // DEBUG screenshot hook: CB_DAY_OFFSET=-2 starts n days away from today.
        if let raw = ProcessInfo.processInfo.environment["CB_DAY_OFFSET"], let n = Int(raw) {
            day = Calendar.current.date(byAdding: .day, value: n, to: day) ?? day
        }
        selectedDay = day
    }

    var today: Date { cal.startOfDay(for: Date()) }
    var isToday: Bool { selectedDay == today }
    var isFuture: Bool { selectedDay > today }

    /// Latest selectable day: +4 weeks (design §1).
    var maxDay: Date { cal.date(byAdding: .day, value: 28, to: today) ?? today }

    var title: String {
        isToday ? "Today" : selectedDay.formatted(.dateTime.month(.abbreviated).day())
    }

    /// The 7 days of the week containing the selection (calendar's week order).
    var weekDays: [Date] {
        guard let start = cal.dateInterval(of: .weekOfYear, for: selectedDay)?.start else {
            return [selectedDay]
        }
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
    }

    var weekRangeLabel: String {
        let style = Date.FormatStyle().month(.abbreviated).day()
        guard let first = weekDays.first, let last = weekDays.last else { return "" }
        return "\(first.formatted(style)) – \(last.formatted(style))"
    }

    func select(_ day: Date) {
        selectedDay = min(cal.startOfDay(for: day), maxDay)
    }

    func shiftWeek(_ delta: Int) {
        if let d = cal.date(byAdding: .weekOfYear, value: delta, to: selectedDay) {
            select(d)
        }
    }

    func backToToday() { selectedDay = today }
}
