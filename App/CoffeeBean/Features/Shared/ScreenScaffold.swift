import SwiftUI

/// Standard dark-background screen chrome with a large navigation title.
struct ScreenScaffold<Content: View>: View {
    let title: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                content()
            }
            .navigationTitle(title)
        }
    }
}
