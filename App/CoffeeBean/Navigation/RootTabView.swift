import SwiftUI
import SwiftData

/// The v1 information architecture: Food (home) · Water · Body · Train.
struct RootTabView: View {
    enum Tab: Hashable { case food, water, body, train }

    @Environment(\.modelContext) private var context
    @State private var selection: Tab = RootTabView.initialTab()
    @State private var dateNav = DateNav()

    var body: some View {
        TabView(selection: $selection) {
            FoodTabView()
                .tabItem { Label("Food", systemImage: "fork.knife") }
                .tag(Tab.food)
            WaterTabView()
                .tabItem { Label("Water", systemImage: "drop.fill") }
                .tag(Tab.water)
            BodyTabView()
                .tabItem { Label("Body", systemImage: "figure.stand") }
                .tag(Tab.body)
            TrainTabView()
                .tabItem { Label("Train", systemImage: "dumbbell.fill") }
                .tag(Tab.train)
        }
        .tint(Theme.accent)
        .environment(dateNav)
        .onAppear { AppSeeder.seedIfNeeded(context) }
    }

    /// Allows a screenshot/debug launch to open a specific tab via the CB_TAB env var.
    static func initialTab() -> Tab {
        switch ProcessInfo.processInfo.environment["CB_TAB"] {
        case "water": return .water
        case "body": return .body
        case "train": return .train
        default: return .food
        }
    }
}
