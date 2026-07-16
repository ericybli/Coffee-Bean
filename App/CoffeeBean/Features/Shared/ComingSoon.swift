import SwiftUI

/// Placeholder body for tabs not yet built out.
struct ComingSoon: View {
    let systemImage: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 44))
                .foregroundStyle(Theme.accent)
            Text("Coming soon")
                .font(.callout)
                .foregroundStyle(Theme.textSecondary)
        }
    }
}
