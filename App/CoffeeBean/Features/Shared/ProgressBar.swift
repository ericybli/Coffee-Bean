import SwiftUI

/// A thin rounded progress bar. Decorative — the surrounding text carries the value for VoiceOver.
struct ProgressBar: View {
    let fraction: Double
    let color: Color
    var height: CGFloat = 9

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(color.opacity(0.15))
                Capsule().fill(color)
                    .frame(width: geo.size.width * min(max(fraction, 0), 1))
            }
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }
}
