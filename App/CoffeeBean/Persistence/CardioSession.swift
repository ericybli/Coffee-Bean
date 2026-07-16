import Foundation
import SwiftData

/// A logged cardio session. kcal is derived from the type's kcal/min rate at display time.
@Model
final class CardioSession {
    var id: UUID = UUID()
    var day: Date = Date()             // startOfDay bucket
    var typeRaw: String = "run"
    var minutes: Double = 0
    var loggedAt: Date = Date()

    init(day: Date, typeRaw: String, minutes: Double, loggedAt: Date = Date()) {
        self.day = day
        self.typeRaw = typeRaw
        self.minutes = minutes
        self.loggedAt = loggedAt
    }
}
