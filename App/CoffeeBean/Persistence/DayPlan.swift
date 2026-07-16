import Foundation
import SwiftData

/// A per-day override of the default weekly split (set via the routine chips).
@Model
final class DayPlan {
    var id: UUID = UUID()
    var day: Date = Date()             // startOfDay bucket
    var routineRaw: String = "rest"

    init(day: Date, routineRaw: String) {
        self.day = day
        self.routineRaw = routineRaw
    }
}
