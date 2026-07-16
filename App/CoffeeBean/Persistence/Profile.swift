import Foundation
import SwiftData

/// Single-user profile (code-enforced singleton). Height drives BMI; unit system is the display toggle.
@Model
final class Profile {
    var id: UUID = UUID()
    var heightCm: Double = 178
    var unitSystemRaw: String = "metric"
    var waterGoalMl: Double = 2000

    init() {}
}
