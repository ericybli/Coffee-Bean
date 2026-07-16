import SwiftUI
import SwiftData

@main
struct CoffeeBeanApp: App {
    var body: some Scene {
        WindowGroup {
            RootTabView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: [
            WeightEntry.self, BodyScan.self, Profile.self,
            DrinkPreset.self, DrinkLog.self,
            Food.self, FoodLogEntry.self,
            CardioSession.self, WorkoutSet.self, DayPlan.self,
            WaistEntry.self,
        ])
    }
}
