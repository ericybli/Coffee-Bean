import Foundation

/// A measurement stored once in canonical SI, displayable in either unit system.
public struct Quantity: Equatable, Sendable {
    public let canonicalValue: Double
    public let kind: QuantityKind

    public init(canonicalValue: Double, kind: QuantityKind) {
        self.canonicalValue = canonicalValue
        self.kind = kind
    }

    /// Numeric value expressed in the given system's display unit.
    public func value(in system: UnitSystem) -> Double {
        let measurement = Measurement(value: canonicalValue, unit: kind.canonicalUnit)
        return measurement.converted(to: kind.displayUnit(for: system)).value
    }
}

public extension Quantity {
    /// Build a canonical Quantity from a value the user entered in `system`'s display unit.
    init?(displayValue: Double, kind: QuantityKind, system: UnitSystem) {
        guard displayValue.isFinite else { return nil }
        let measurement = Measurement(value: displayValue, unit: kind.displayUnit(for: system))
        let canonical = measurement.converted(to: kind.canonicalUnit).value
        self.init(canonicalValue: canonical, kind: kind)
    }

    /// Feet + whole inches with a 12-inch carry. Only meaningful for `.height`.
    func heightFeetInches() -> FeetInches {
        let totalInches = value(in: .imperial) // canonical cm -> inches
        var feet = Int(totalInches / 12)
        var inches = Int((totalInches - Double(feet) * 12).rounded())
        if inches == 12 { feet += 1; inches = 0 }
        return FeetInches(feet: feet, inches: inches)
    }
}
