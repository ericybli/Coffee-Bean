import Foundation

/// Demo data used only when the app is launched with the CB_SEED=1 environment variable
/// (for populated screenshots). Never seeds in normal use.
enum SampleData {
    /// ~3 weeks of weigh-ins: a gentle lean-bulk climb with realistic daily water-weight noise.
    static func weightEntries() -> [WeightEntry] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let series: [Double] = [
            72.0, 72.3, 71.9, 72.1, 72.4, 72.2, 72.5, 72.1, 72.6, 72.3, 72.7,
            72.4, 72.8, 72.5, 72.9, 72.6, 73.0, 72.7, 73.1, 72.8, 73.2,
        ]
        return series.enumerated().map { i, kg in
            let d = cal.date(byAdding: .day, value: -(series.count - 1 - i), to: today)!
            return WeightEntry(date: d, massKg: kg)
        }
    }

    static func dexaScan() -> BodyScan {
        let d = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()
        return BodyScan(date: d, bodyFatFraction: 0.142, leanMassKg: 59.8,
                        fatMassKg: 12.6, rmrKcal: 1720, isRMRAuthoritative: true)
    }
}
