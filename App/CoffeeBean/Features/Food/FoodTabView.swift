import SwiftUI
import SwiftData
import CoffeeBeanCore

/// Food (home): calories + macros vs targets, the meal diary, and quick add.
/// Scoped to the shared selected day — past days are editable (backfill),
/// future days are read-only (design §1).
struct FoodTabView: View {
    @Environment(\.modelContext) private var context
    @Environment(DateNav.self) private var nav
    @Query(sort: \FoodLogEntry.loggedAt) private var entries: [FoodLogEntry]
    @Query private var foods: [Food]
    @Query(sort: \BodyScan.date, order: .reverse) private var scans: [BodyScan]
    @Query(sort: \WeightEntry.date, order: .reverse) private var weights: [WeightEntry]
    @Query private var profiles: [Profile]

    @State private var addSlot: MealSlot?
    @State private var pendingScan = false
    @State private var didAutoOpen = false

    private var dayEntries: [FoodLogEntry] {
        entries.filter { Calendar.current.isDate($0.day, inSameDayAs: nav.selectedDay) }
    }

    /// Full spec §5.1 RMR priority via CoffeeBeanCore: DEXA > Katch-McArdle > Mifflin-St Jeor.
    private var rmr: Double {
        EnergyResolver.rmr(profile: profiles.first, scans: scans,
                           latestWeightKg: weights.first?.massKg).value
    }

    /// Adaptive TDEE (§5.3): empirical maintenance from the last 3 weeks of
    /// intake + weight trend. Replaces RMR×PAL only once trustworthy
    /// (≥14 logged days and ≥8 weigh-ins in the window).
    private var adaptiveTDEE: Double? {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        guard let windowStart = cal.date(byAdding: .day, value: -21, to: today) else { return nil }

        // Complete days only — today and sub-1000 kcal days are partial logs
        // that would drag the mean down and fake a deficit.
        let byDay = Dictionary(grouping: entries.filter { $0.day >= windowStart && $0.day < today }) {
            cal.startOfDay(for: $0.day)
        }
        let dayTotals = byDay.values.map { $0.reduce(0) { $0 + $1.kcal } }.filter { $0 >= 1000 }
        guard !dayTotals.isEmpty else { return nil }
        let meanIntake = dayTotals.reduce(0, +) / Double(dayTotals.count)

        let windowWeighIns = weights.filter { $0.date >= windowStart }
            .map { WeighIn(date: $0.date, massKg: $0.massKg) }
            .sorted { $0.date < $1.date }
        let points = TrendEngine(alpha: 0.28).trend(from: windowWeighIns)
        guard let first = points.first, let last = points.last, points.count >= 2 else { return nil }
        let windowDays = max(1, cal.dateComponents([.day], from: first.date, to: last.date).day ?? 1)

        let result = AdaptiveTDEE.evaluate(
            meanIntakeKcal: meanIntake, trendStartKg: first.trend, trendEndKg: last.trend,
            windowDays: windowDays, daysLogged: dayTotals.count, weighIns: windowWeighIns.count)
        return result.isTrustworthy ? result.maintenanceKcal : nil
    }

    var body: some View {
        let day = dayEntries
        let consumed = day.reduce(0) { $0 + $1.kcal }
        let macros = Macros(
            proteinG: day.reduce(0) { $0 + $1.proteinG },
            carbG: day.reduce(0) { $0 + $1.carbG },
            fatG: day.reduce(0) { $0 + $1.fatG })
        let bySlot = Dictionary(grouping: day) { MealSlot(rawValue: $0.mealSlotRaw) ?? .extra }
        let adaptive = adaptiveTDEE
        let targets = NutritionTargets(rmr: rmr, profile: profiles.first, adaptiveTDEE: adaptive)

        return DatedScreenScaffold {
            ScrollView {
                VStack(spacing: 16) {
                    CaloriesCard(consumed: consumed, target: targets.calorieTarget,
                                 tdee: targets.tdee, tdeeMeasured: adaptive != nil)
                    MacrosCard(consumed: macros, target: targets.macroTargets)
                    MealDiaryCard(entriesBySlot: bySlot,
                                  allowAdd: !nav.isFuture,
                                  onAdd: { open($0, scan: false) },
                                  onDelete: { context.delete($0) })
                    if !nav.isFuture { ctaRow }
                }
                .padding(20)
            }
        }
        .sheet(item: $addSlot, onDismiss: { pendingScan = false }) { slot in
            AddFoodSheet(slot: slot, foods: foods,
                         initialScreen: pendingScan ? .barcode : .browse,
                         usdaApiKey: profiles.first?.usdaApiKey ?? "",
                         onLog: { food, servings in log(food, servings: servings, slot: slot) },
                         onQuickAdd: { kcal, p, c, f in quickAdd(kcal: kcal, p: p, c: c, f: f, slot: slot) })
        }
        .onAppear {
            guard !didAutoOpen, ProcessInfo.processInfo.environment["CB_OPEN_ADD"] == "1" else { return }
            didAutoOpen = true
            open(defaultSlot(), scan: ProcessInfo.processInfo.environment["CB_SCAN"] != nil)
        }
    }

    private var ctaRow: some View {
        HStack(spacing: 12) {
            Button { open(defaultSlot(), scan: true) } label: {
                Label("Scan to log", systemImage: "barcode.viewfinder").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent).tint(Theme.accent)
            Button { open(defaultSlot(), scan: false) } label: {
                Label("Search", systemImage: "magnifyingglass").frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered).tint(Theme.accent)
        }
    }

    private func open(_ slot: MealSlot, scan: Bool) {
        pendingScan = scan
        addSlot = slot
    }

    private func defaultSlot() -> MealSlot {
        switch Calendar.current.component(.hour, from: Date()) {
        case ..<11: return .breakfast
        case ..<16: return .lunch
        case ..<21: return .dinner
        default: return .snacks
        }
    }

    private func log(_ food: Food, servings: Double, slot: MealSlot) {
        let m = food.totals(servings: servings)
        food.lastUsedAt = Date()
        context.insert(FoodLogEntry(
            day: nav.selectedDay, mealSlotRaw: slot.rawValue,
            foodID: food.id, foodName: food.name, servingLabel: food.servingLabel, quantity: servings,
            kcal: m.kcal, proteinG: m.protein, carbG: m.carb, fatG: m.fat,
            loggedAt: nav.isToday ? Date() : nav.selectedDay))
    }

    /// MFP-style quick add: calories (+optional macros) with no library food.
    private func quickAdd(kcal: Double, p: Double, c: Double, f: Double, slot: MealSlot) {
        let detail = (p + c + f) > 0 ? "P \(Int(p)) · C \(Int(c)) · F \(Int(f))" : "calories only"
        context.insert(FoodLogEntry(
            day: nav.selectedDay, mealSlotRaw: slot.rawValue,
            foodID: nil, foodName: "Quick add", servingLabel: detail, quantity: 1,
            kcal: kcal, proteinG: p, carbG: c, fatG: f,
            loggedAt: nav.isToday ? Date() : nav.selectedDay))
    }
}
