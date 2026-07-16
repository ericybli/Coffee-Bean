import SwiftUI
import SwiftData
import CoffeeBeanCore

/// Food (home): calories + macros vs targets, and the meal diary.
struct FoodTabView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \FoodLogEntry.loggedAt) private var entries: [FoodLogEntry]
    @Query private var foods: [Food]
    @Query private var scans: [BodyScan]

    @State private var addSlot: MealSlot?

    private var todayEntries: [FoodLogEntry] {
        entries.filter { Calendar.current.isDateInToday($0.day) }
    }
    private var rmr: Double { scans.first(where: { $0.isRMRAuthoritative })?.rmrKcal ?? 1600 }
    private var targets: NutritionTargets { NutritionTargets(rmr: rmr) }
    private var consumedKcal: Double { todayEntries.reduce(0) { $0 + $1.kcal } }
    private var consumedMacros: Macros {
        Macros(proteinG: todayEntries.reduce(0) { $0 + $1.proteinG },
               carbG: todayEntries.reduce(0) { $0 + $1.carbG },
               fatG: todayEntries.reduce(0) { $0 + $1.fatG })
    }
    private var entriesBySlot: [MealSlot: [FoodLogEntry]] {
        Dictionary(grouping: todayEntries) { MealSlot(rawValue: $0.mealSlotRaw) ?? .extra }
    }

    var body: some View {
        ScreenScaffold(title: "Food") {
            ScrollView {
                VStack(spacing: 16) {
                    CaloriesCard(consumed: consumedKcal, target: targets.calorieTarget, tdee: targets.tdee)
                    MacrosCard(consumed: consumedMacros, target: targets.macroTargets)
                    MealDiaryCard(entriesBySlot: entriesBySlot,
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
        .onAppear(perform: bootstrap)
    }

    private func log(_ food: Food, servings: Double, slot: MealSlot) {
        let t = food.totals(servings: servings)
        food.lastUsedAt = Date()
        context.insert(FoodLogEntry(
            day: Calendar.current.startOfDay(for: Date()), mealSlotRaw: slot.rawValue,
            foodID: food.id, foodName: food.name, servingLabel: food.servingLabel, quantity: servings,
            kcal: t.kcal, proteinG: t.protein, carbG: t.carb, fatG: t.fat))
    }

    private func bootstrap() {
        guard foods.isEmpty else { return }
        let seeded = SampleData.libraryFoods()
        for f in seeded { context.insert(f) }
        if ProcessInfo.processInfo.environment["CB_SEED"] == "1" {
            for e in SampleData.foodLogEntries(from: seeded) { context.insert(e) }
        }
    }
}
