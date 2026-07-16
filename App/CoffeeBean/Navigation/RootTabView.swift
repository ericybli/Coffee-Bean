import SwiftUI

/// The v1 information architecture: Food (home) · Water · Body · Train.
struct RootTabView: View {
    var body: some View {
        TabView {
            FoodTabView()
                .tabItem { Label("Food", systemImage: "fork.knife") }
            WaterTabView()
                .tabItem { Label("Water", systemImage: "drop.fill") }
            BodyTabView()
                .tabItem { Label("Body", systemImage: "figure.stand") }
            TrainTabView()
                .tabItem { Label("Train", systemImage: "dumbbell.fill") }
        }
        .tint(Theme.accent)
    }
}
