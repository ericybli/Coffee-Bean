import Foundation

/// The 5-day split routines + rest.
enum Routine: String, CaseIterable, Identifiable {
    case chest, back, leg, shoulder, arm, rest

    var id: String { rawValue }

    var title: String {
        switch self {
        case .chest: return "Chest"
        case .back: return "Back"
        case .leg: return "Leg"
        case .shoulder: return "Shoulder"
        case .arm: return "Arm"
        case .rest: return "Rest"
        }
    }

    var dayTitle: String { self == .rest ? "Rest day" : "\(title) Day" }

    /// Default weekly split: Mon Chest, Tue Back, Wed Leg, Thu Shoulder, Fri Arm, Sat+Sun Rest.
    static func defaultFor(weekday: Int) -> Routine {
        switch weekday {                 // Calendar weekday: 1 = Sunday
        case 2: return .chest
        case 3: return .back
        case 4: return .leg
        case 5: return .shoulder
        case 6: return .arm
        default: return .rest
        }
    }

    /// The four default exercises per routine (from the 20-exercise catalog).
    var defaultExercises: [CatalogExercise] {
        CatalogExercise.catalog.filter { $0.group == self }
    }
}

/// Static v1 exercise catalog (custom exercises come later).
struct CatalogExercise: Identifiable, Hashable {
    let name: String
    let group: Routine
    let defaultWeightKg: Double

    var id: String { name }

    static let catalog: [CatalogExercise] = [
        .init(name: "Bench Press", group: .chest, defaultWeightKg: 60),
        .init(name: "Incline DB Press", group: .chest, defaultWeightKg: 22.5),
        .init(name: "Cable Fly", group: .chest, defaultWeightKg: 15),
        .init(name: "Dips", group: .chest, defaultWeightKg: 0),
        .init(name: "Deadlift", group: .back, defaultWeightKg: 100),
        .init(name: "Pull-up", group: .back, defaultWeightKg: 0),
        .init(name: "Barbell Row", group: .back, defaultWeightKg: 60),
        .init(name: "Lat Pulldown", group: .back, defaultWeightKg: 50),
        .init(name: "Squat", group: .leg, defaultWeightKg: 80),
        .init(name: "Leg Press", group: .leg, defaultWeightKg: 120),
        .init(name: "Romanian Deadlift", group: .leg, defaultWeightKg: 70),
        .init(name: "Leg Curl", group: .leg, defaultWeightKg: 40),
        .init(name: "Overhead Press", group: .shoulder, defaultWeightKg: 40),
        .init(name: "DB Lateral Raise", group: .shoulder, defaultWeightKg: 10),
        .init(name: "Rear Delt Fly", group: .shoulder, defaultWeightKg: 12.5),
        .init(name: "Cable Lateral Raise", group: .shoulder, defaultWeightKg: 7.5),
        .init(name: "Barbell Curl", group: .arm, defaultWeightKg: 30),
        .init(name: "Hammer Curl", group: .arm, defaultWeightKg: 12.5),
        .init(name: "Triceps Pushdown", group: .arm, defaultWeightKg: 25),
        .init(name: "Skull Crusher", group: .arm, defaultWeightKg: 25),
    ]
}

/// Cardio types with their kcal/min planning rates (design §5).
enum CardioType: String, CaseIterable, Identifiable {
    case run, bike, row, inclineWalk, swim

    var id: String { rawValue }

    var title: String {
        switch self {
        case .run: return "Run"
        case .bike: return "Bike"
        case .row: return "Row"
        case .inclineWalk: return "Incline Walk"
        case .swim: return "Swim"
        }
    }

    var kcalPerMin: Double {
        switch self {
        case .run: return 11
        case .bike: return 8
        case .row: return 10
        case .inclineWalk: return 7
        case .swim: return 9
        }
    }
}
