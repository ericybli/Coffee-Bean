import Foundation
import SwiftData

/// One set of a weights exercise. Grouped into a day's session by the `day` bucket;
/// exercises are ordered by `exerciseOrder`, sets within one by `setIndex`.
/// No relationships — CloudKit-rule-trivial, like FoodLogEntry.
@Model
final class WorkoutSet {
    var id: UUID = UUID()
    var day: Date = Date()             // startOfDay bucket
    var exerciseName: String = ""
    var muscleGroupRaw: String = "chest"
    var exerciseOrder: Int = 0
    var setIndex: Int = 0
    var weightKg: Double = 20
    var reps: Int = 10
    var loggedAt: Date = Date()

    init(day: Date, exerciseName: String, muscleGroupRaw: String, exerciseOrder: Int,
         setIndex: Int, weightKg: Double, reps: Int, loggedAt: Date = Date()) {
        self.day = day
        self.exerciseName = exerciseName
        self.muscleGroupRaw = muscleGroupRaw
        self.exerciseOrder = exerciseOrder
        self.setIndex = setIndex
        self.weightKg = weightKg
        self.reps = reps
        self.loggedAt = loggedAt
    }

    var volumeKg: Double { weightKg * Double(reps) }
}
