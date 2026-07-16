import Foundation
import SwiftData

/// A periodic body-composition scan (DEXA). Feeds the RMR resolver and body-comp charts.
@Model
final class BodyScan {
    var id: UUID = UUID()
    var date: Date = Date()
    var bodyFatFraction: Double? = nil   // 0...1
    var leanMassKg: Double? = nil
    var fatMassKg: Double? = nil
    var rmrKcal: Double? = nil
    var isRMRAuthoritative: Bool = false

    init(date: Date = Date(), bodyFatFraction: Double? = nil, leanMassKg: Double? = nil,
         fatMassKg: Double? = nil, rmrKcal: Double? = nil, isRMRAuthoritative: Bool = false) {
        self.date = date
        self.bodyFatFraction = bodyFatFraction
        self.leanMassKg = leanMassKg
        self.fatMassKg = fatMassKg
        self.rmrKcal = rmrKcal
        self.isRMRAuthoritative = isRMRAuthoritative
    }
}
