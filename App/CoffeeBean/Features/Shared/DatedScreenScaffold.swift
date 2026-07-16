import SwiftUI
import SwiftData

/// Screen chrome for the dated tabs (Food, Water, Train): the nav title is the selected
/// date ("Today" / "Jul 14"), with the week strip pinned above the content, a calendar
/// sheet, a Back-to-today pill when off today, and settings access.
struct DatedScreenScaffold<Content: View>: View {
    @Environment(DateNav.self) private var nav
    @ViewBuilder var content: () -> Content

    // "Logged" = any food or water entry that day (design §1).
    @Query private var foodEntries: [FoodLogEntry]
    @Query private var drinkLogs: [DrinkLog]

    @State private var showCalendar =
        ProcessInfo.processInfo.environment["CB_OPEN_CALENDAR"] == "1"
    @State private var showSettings =
        ProcessInfo.processInfo.environment["CB_OPEN_SETTINGS"] == "1"

    private var loggedDays: Set<Date> {
        let cal = Calendar.current
        var days = Set(foodEntries.map { cal.startOfDay(for: $0.day) })
        days.formUnion(drinkLogs.map { cal.startOfDay(for: $0.timestamp) })
        return days
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                VStack(spacing: 0) {
                    WeekStrip(nav: nav, loggedDays: loggedDays)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 6)
                    content()
                }
            }
            .navigationTitle(nav.title)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if !nav.isToday {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Back to today") { nav.backToToday() }
                            .font(.caption).bold()
                            .buttonStyle(.bordered).tint(Theme.accent)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showCalendar = true } label: { Image(systemName: "calendar") }
                        .tint(Theme.textSecondary)
                        .accessibilityLabel("Pick a date")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: { Image(systemName: "gearshape") }
                        .tint(Theme.textSecondary)
                        .accessibilityLabel("Settings")
                }
            }
            .navigationDestination(isPresented: $showSettings) { SettingsView() }
            .sheet(isPresented: $showCalendar) { calendarSheet }
        }
    }

    private var calendarSheet: some View {
        CalendarMonthView(nav: nav, loggedDays: loggedDays) { _ in
            showCalendar = false
        }
        .presentationDetents([.medium])
        .presentationBackground(Theme.sheet)
    }
}
