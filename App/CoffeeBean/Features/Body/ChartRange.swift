import Foundation

/// Time window for the body-composition charts.
enum ChartRange: String, CaseIterable, Identifiable {
    case twoWeeks = "2W"
    case month = "1M"
    case threeMonths = "3M"
    case sixMonths = "6M"
    case year = "1Y"

    var id: String { rawValue }

    var days: Int {
        switch self {
        case .twoWeeks: return 14
        case .month: return 30
        case .threeMonths: return 90
        case .sixMonths: return 180
        case .year: return 365
        }
    }
}
