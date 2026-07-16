import Foundation
import SwiftData

/// A raw daily scale weigh-in (canonical kg). The smoothed trend is derived, never stored.
/// Authored to CloudKit-sync rules (all properties defaulted, UUID id, no unique constraint).
@Model
final class WeightEntry {
    var id: UUID = UUID()
    var date: Date = Date()
    var massKg: Double = 0

    init(date: Date = Date(), massKg: Double = 0) {
        self.date = date
        self.massKg = massKg
    }
}
