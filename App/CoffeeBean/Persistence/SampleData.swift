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

    // MARK: Food

    /// A small starter library of common foods.
    static func libraryFoods() -> [Food] {
        [
            Food(name: "Chicken breast", kcalPer100g: 165, proteinPer100g: 31,
                 carbPer100g: 0, fatPer100g: 3.6, servingLabel: "100 g", servingGrams: 100),
            Food(name: "White rice (cooked)", kcalPer100g: 130, proteinPer100g: 2.7,
                 carbPer100g: 28, fatPer100g: 0.3, servingLabel: "1 cup", servingGrams: 158),
            Food(name: "Rolled oats", kcalPer100g: 379, proteinPer100g: 13,
                 carbPer100g: 67, fatPer100g: 6.5, servingLabel: "1/2 cup", servingGrams: 40),
            Food(name: "Whole egg", kcalPer100g: 155, proteinPer100g: 13,
                 carbPer100g: 1.1, fatPer100g: 11, servingLabel: "1 egg", servingGrams: 50),
            Food(name: "Banana", kcalPer100g: 89, proteinPer100g: 1.1,
                 carbPer100g: 23, fatPer100g: 0.3, servingLabel: "1 medium", servingGrams: 118),
            Food(name: "Whey protein", isFavorite: true, kcalPer100g: 400, proteinPer100g: 80,
                 carbPer100g: 8, fatPer100g: 6, servingLabel: "1 scoop", servingGrams: 30),
        ]
    }

    /// A partial day of diary entries built from the starter library.
    static func foodLogEntries(from foods: [Food]) -> [FoodLogEntry] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())

        func entry(_ food: Food, _ servings: Double, _ slot: MealSlot, _ hour: Int) -> FoodLogEntry {
            let t = food.totals(servings: servings)
            return FoodLogEntry(
                day: today, mealSlotRaw: slot.rawValue, foodID: food.id, foodName: food.name,
                servingLabel: food.servingLabel, quantity: servings,
                kcal: t.kcal, proteinG: t.protein, carbG: t.carb, fatG: t.fat,
                loggedAt: cal.date(bySettingHour: hour, minute: 0, second: 0, of: today) ?? today)
        }
        func food(_ name: String) -> Food? { foods.first { $0.name == name } }

        var out: [FoodLogEntry] = []
        if let f = food("Rolled oats") { out.append(entry(f, 1.5, .breakfast, 8)) }
        if let f = food("Whole egg") { out.append(entry(f, 3, .breakfast, 8)) }
        if let f = food("Chicken breast") { out.append(entry(f, 2, .lunch, 13)) }
        if let f = food("White rice (cooked)") { out.append(entry(f, 1.5, .lunch, 13)) }
        if let f = food("Whey protein") { out.append(entry(f, 1, .snacks, 16)) }
        if let f = food("Banana") { out.append(entry(f, 1, .snacks, 16)) }
        return out
    }

    // MARK: Train

    /// A few cardio days ending with a 20-min run today.
    static func cardioSessions() -> [CardioSession] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        func day(_ back: Int) -> Date { cal.date(byAdding: .day, value: -back, to: today)! }
        return [
            CardioSession(day: day(6), typeRaw: CardioType.inclineWalk.rawValue, minutes: 30),
            CardioSession(day: day(4), typeRaw: CardioType.row.rawValue, minutes: 25),
            CardioSession(day: day(2), typeRaw: CardioType.bike.rawValue, minutes: 15),
            CardioSession(day: day(0), typeRaw: CardioType.run.rawValue, minutes: 20),
        ]
    }

    /// Today's session (3 exercises × 3 sets of today's default routine) plus the same
    /// session at -7/-14/-21 days with slightly lower loads, so "Previous" comparisons
    /// and the same-routine volume chart populate.
    static func workoutSets() -> [WorkoutSet] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let routine = Routine.defaultFor(weekday: cal.component(.weekday, from: today))
        let exercises = Array((routine == .rest ? Routine.chest : routine).defaultExercises.prefix(3))

        var out: [WorkoutSet] = []
        for (back, drop) in [(21, 3), (14, 2), (7, 1), (0, 0)] {
            let day = cal.date(byAdding: .day, value: -back, to: today)!
            for (order, ex) in exercises.enumerated() {
                let weight = max(2.5, ex.defaultWeightKg - Double(drop) * 2.5)
                for setIndex in 0..<3 {
                    out.append(WorkoutSet(day: day, exerciseName: ex.name,
                                          muscleGroupRaw: ex.group.rawValue,
                                          exerciseOrder: order, setIndex: setIndex,
                                          weightKg: weight, reps: 8))
                }
            }
        }
        return out
    }
}
