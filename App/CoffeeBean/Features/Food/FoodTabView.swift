import SwiftUI
import SwiftData
import CoffeeBeanCore

/// Food (home): calories + macros vs targets, and the meal diary.
struct FoodTabView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \FoodLogEntry.loggedAt) private var entries: [FoodLogEntry]
    @Query private var foods: [Food]
    @Query(sort: \BodyScan.date, order: .reverse) private var scans: [BodyScan]

    @State private var addSlot: MealSlot?

    private var todayEntries: [FoodLogEntry] {
        entries.filter { Calendar.current.isDateInToday($0.day) }
    }

    /// RMR by spec §5.1 priority: latest authoritative DEXA RMR → Katch-McArdle from the latest
    /// scan with lean mass → 1600 fallback (Mifflin needs sex/age/weight the v1 Profile lacks).
    private var rmr: Double {
        if let measured = scans.first(where: { $0.isRMRAuthoritative && $0.rmrKcal != nil })?.rmrKcal {
            return measured
        }
        if let lean = scans.first(where: { $0.leanMassKg != nil })?.leanMassKg {
            return BMR.katchMcArdle(leanMassKg: lean)
        }
        return 1600
    }

    var body: some View {
        let today = todayEntries
        let consumed = today.reduce(0) { $0 + $1.kcal }
        let macros = Macros(
            proteinG: today.reduce(0) { $0 + $1.proteinG },
            carbG: today.reduce(0) { $0 + $1.carbG },
            fatG: today.reduce(0) { $0 + $1.fatG })
        let bySlot = Dictionary(grouping: today) { MealSlot(rawValue: $0.mealSlotRaw) ?? .extra }
        let targets = NutritionTargets(rmr: rmr)

        return ScreenScaffold(title: "Food") {
            ScrollView {
                VStack(spacing: 16) {
                    CaloriesCard(consumed: consumed, target: targets.calorieTarget, tdee: targets.tdee)
                    MacrosCard(consumed: macros, target: targets.macroTargets)
                    MealDiaryCard(entriesBySlot: bySlot,
                                  onAdd: { addSlot = $0 },
                                  onDelete: { context.delete($0) })
                }
                .padding(20)
            }
        }
        .sheet(item: $addSlot) { slot in
            AddFoodSheet(slot: slot, foods: foods) { food, servings in
                log(food, servings: servings, slot: slot)
            }
        }
    }

    private func log(_ food: Food, servings: Double, slot: MealSlot) {
        let m = food.totals(servings: servings)
        food.lastUsedAt = Date()
        context.insert(FoodLogEntry(
            day: Calendar.current.startOfDay(for: Date()), mealSlotRaw: slot.rawValue,
            foodID: food.id, foodName: food.name, servingLabel: food.servingLabel, quantity: servings,
            kcal: m.kcal, proteinG: m.protein, carbG: m.carb, fatG: m.fat))
    }
}
