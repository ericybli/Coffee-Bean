import Foundation
import SwiftData

/// One app-level seed so the starter library + (optional) demo data exist regardless of
/// which tab is shown first — keeps energy targets DEXA-consistent on CB_SEED launches.
enum AppSeeder {
    static func seedIfNeeded(_ context: ModelContext) {
        func isEmpty<T: PersistentModel>(_ type: T.Type) -> Bool {
            ((try? context.fetchCount(FetchDescriptor<T>())) ?? 0) == 0
        }

        // Always-on defaults.
        if isEmpty(Profile.self) { context.insert(Profile()) }
        if isEmpty(DrinkPreset.self) {
            for p in SampleData.defaultDrinkPresets() { context.insert(p) }
        }
        var foods: [Food] = (try? context.fetch(FetchDescriptor<Food>())) ?? []
        if foods.isEmpty {
            foods = SampleData.libraryFoods()
            for f in foods { context.insert(f) }
        }

        // Demo data for screenshots only.
        guard ProcessInfo.processInfo.environment["CB_SEED"] == "1" else { return }
        if isEmpty(WeightEntry.self) {
            for e in SampleData.weightEntries() { context.insert(e) }
        }
        if isEmpty(BodyScan.self) { context.insert(SampleData.dexaScan()) }
        if isEmpty(DrinkLog.self) {
            for l in SampleData.drinkLogs() { context.insert(l) }
        }
        if isEmpty(FoodLogEntry.self) {
            for e in SampleData.foodLogEntries(from: foods) { context.insert(e) }
        }
    }
}
