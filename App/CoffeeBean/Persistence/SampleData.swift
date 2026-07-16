import Foundation

/// Default seed content, plus demo data used only when the app is launched with CB_SEED=1
/// (for populated screenshots). Default drink presets seed on first launch regardless.
enum SampleData {
    // MARK: Body

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

    // MARK: Water

    /// Seeded on first launch so the water tracker is usable out of the box.
    static func defaultDrinkPresets() -> [DrinkPreset] {
        [
            DrinkPreset(label: "Glass", volumeMl: 250, drinkTypeRaw: "water",
                        iconName: "drop.fill", sortIndex: 0),
            DrinkPreset(label: "Bottle", volumeMl: 500, drinkTypeRaw: "water",
                        iconName: "waterbottle.fill", sortIndex: 1),
            DrinkPreset(label: "Coffee", volumeMl: 300, drinkTypeRaw: "coffee",
                        iconName: "cup.and.saucer.fill", sortIndex: 2),
        ]
    }

    /// A few drinks earlier today (total 1,300 ml) for a populated ring in screenshots.
    static func drinkLogs() -> [DrinkLog] {
        let cal = Calendar.current
        let now = Date()
        func at(_ h: Int, _ m: Int) -> Date { cal.date(bySettingHour: h, minute: m, second: 0, of: now) ?? now }
        return [
            DrinkLog(timestamp: at(8, 15), volumeMl: 300, drinkTypeRaw: "coffee", name: "Coffee"),
            DrinkLog(timestamp: at(10, 30), volumeMl: 500, drinkTypeRaw: "water", name: "Bottle"),
            DrinkLog(timestamp: at(13, 0), volumeMl: 250, drinkTypeRaw: "water", name: "Glass"),
            DrinkLog(timestamp: at(15, 45), volumeMl: 250, drinkTypeRaw: "water", name: "Glass"),
        ]
    }
}
