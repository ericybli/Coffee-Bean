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

    var body: some View {
        let day = dayEntries
        let consumed = day.reduce(0) { $0 + $1.kcal }
        let macros = Macros(
            proteinG: day.reduce(0) { $0 + $1.proteinG },
            carbG: day.reduce(0) { $0 + $1.carbG },
            fatG: day.reduce(0) { $0 + $1.fatG })
        let bySlot = Dictionary(grouping: day) { MealSlot(rawValue: $0.mealSlotRaw) ?? .extra }
        let targets = NutritionTargets(rmr: rmr, profile: profiles.first)

        return DatedScreenScaffold {
            ScrollView {
                VStack(spacing: 16) {
                    CaloriesCard(consumed: consumed, target: targets.calorieTarget, tdee: targets.tdee)
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
