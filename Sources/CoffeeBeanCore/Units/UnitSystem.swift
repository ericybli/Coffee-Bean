import Foundation

public enum UnitSystem: String, Codable, CaseIterable, Sendable {
    case metric
    case imperial
}

public enum QuantityKind: Sendable {
    case bodyMass, foodMass, volume, height, energy

    /// The Foundation unit used for canonical (metric/SI) storage.
    var canonicalUnit: Dimension {
        switch self {
        case .bodyMass: return UnitMass.kilograms
        case .foodMass: return UnitMass.grams
        case .volume:   return UnitVolume.milliliters
        case .height:   return UnitLength.centimeters
        case .energy:   return UnitEnergy.kilocalories
        }
    }

    /// The display unit for the given system.
    func displayUnit(for system: UnitSystem) -> Dimension {
        switch (self, system) {
        case (.bodyMass, .imperial): return UnitMass.pounds
        case (.foodMass, .imperial): return UnitMass.ounces
        case (.volume,   .imperial): return UnitVolume.fluidOunces   // US
        case (.height,   .imperial): return UnitLength.inches
        default: return canonicalUnit                                // metric, or energy (kcal both)
        }
    }
}
