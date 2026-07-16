import SwiftUI
import SwiftData

@main
struct CoffeeBeanApp: App {
    var body: some Scene {
        WindowGroup {
            RootTabView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: [WeightEntry.self, BodyScan.self, Profile.self])
    }
}
