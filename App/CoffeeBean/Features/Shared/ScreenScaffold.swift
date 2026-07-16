import SwiftUI

/// Standard dark-background screen chrome with a large navigation title + settings access.
struct ScreenScaffold<Content: View>: View {
    let title: String
    @ViewBuilder var content: () -> Content

    // DEBUG screenshot hook: CB_OPEN_SETTINGS=1 starts with Settings pushed.
    @State private var showSettings =
        ProcessInfo.processInfo.environment["CB_OPEN_SETTINGS"] == "1"

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                content()
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                    }
                    .tint(Theme.textSecondary)
                    .accessibilityLabel("Settings")
                }
            }
            .navigationDestination(isPresented: $showSettings) { SettingsView() }
        }
    }
}
