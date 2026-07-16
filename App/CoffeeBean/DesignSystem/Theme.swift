import SwiftUI

/// Coffee Bean design tokens (dark-first). Hex values approximate the handoff's
/// oklch palette; refine when the asset catalog / color set lands.
enum Theme {
    // Surfaces
    static let background = Color(hex: 0x131110)   // warm near-black
    static let card = Color(hex: 0x1D1A17)
    static let sheet = Color(hex: 0x1A1815)

    // Text
    static let textPrimary = Color(hex: 0xF2EDE6)
    static let textSecondary = Color(hex: 0xF2EDE6).opacity(0.6)

    // Semantic metric hues (fixed per metric across the app)
    static let accent = Color(hex: 0xE6A23C)    // warm amber — energy / calories / selection
    static let protein = Color(hex: 0x3FBFB0)   // teal
    static let carbs = Color(hex: 0xD8B84A)     // gold
    static let fat = Color(hex: 0xC77DB0)       // pink-violet
    static let water = Color(hex: 0x4A90D9)     // blue
    static let positive = Color(hex: 0x5BB06F)  // green — on-track
    static let negative = Color(hex: 0xD9553F)  // red — delete / over
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}
