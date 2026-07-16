import Foundation
import CoffeeBeanCore

/// Display-side unit conversion (canonical SI in, formatted display out) via CoffeeBeanCore.
enum Units {
    static func massValue(_ kg: Double, _ s: UnitSystem) -> Double {
        Quantity(canonicalValue: kg, kind: .bodyMass).value(in: s)
    }

    static func mass(_ kg: Double, _ s: UnitSystem, decimals: Int = 1) -> String {
        String(format: "%.\(decimals)f %@", massValue(kg, s), s == .metric ? "kg" : "lb")
    }

    static func volume(_ ml: Double, _ s: UnitSystem) -> String {
        s == .metric
            ? "\(Int(ml)) ml"
            : "\(Int(Quantity(canonicalValue: ml, kind: .volume).value(in: s).rounded())) fl oz"
    }

    static func volumeGoal(_ ml: Double, _ s: UnitSystem) -> String {
        s == .metric
            ? String(format: "of %.1f L", ml / 1000)
            : "of \(Int(Quantity(canonicalValue: ml, kind: .volume).value(in: s).rounded())) fl oz"
    }

    static func height(_ cm: Double, _ s: UnitSystem) -> String {
        guard s == .imperial else { return "\(Int(cm.rounded())) cm" }
        let fi = Quantity(canonicalValue: cm, kind: .height).heightFeetInches()
        return "\(fi.feet) ft \(fi.inches) in"
    }

    /// Plain length (waist etc.): cm ⇄ decimal inches.
    static func lengthValue(_ cm: Double, _ s: UnitSystem) -> Double {
        Quantity(canonicalValue: cm, kind: .height).value(in: s)
    }

    static func length(_ cm: Double, _ s: UnitSystem) -> String {
        String(format: "%.1f %@", lengthValue(cm, s), s == .metric ? "cm" : "in")
    }
}
