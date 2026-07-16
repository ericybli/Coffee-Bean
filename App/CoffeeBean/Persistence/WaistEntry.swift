import Foundation
import SwiftData

/// A waist measurement (canonical cm). Smoothed the same way as weight.
@Model
final class WaistEntry {
    var id: UUID = UUID()
    var date: Date = Date()
    var waistCm: Double = 0

    init(date: Date = Date(), waistCm: Double = 0) {
        self.date = date
        self.waistCm = waistCm
    }
}
