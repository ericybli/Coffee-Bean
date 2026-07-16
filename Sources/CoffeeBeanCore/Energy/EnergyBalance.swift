import Foundation

public struct ExpenditureInputs: Sendable {
    public let rmr: Double
    public let activeEnergyKcal: Double
    public let tefMode: TEFMode
    public init(rmr: Double, activeEnergyKcal: Double, tefMode: TEFMode) {
        self.rmr = rmr
        self.activeEnergyKcal = activeEnergyKcal
        self.tefMode = tefMode
    }
}

public enum EnergyBalance {
    /// TDEE = RMR + active energy + TEF (TEF is a function of intake, not of expenditure).
    public static func staticTDEE(rmr: Double, activeEnergyKcal: Double,
                                  intakeKcal: Double, macros: Macros?, tefMode: TEFMode) -> Double {
        rmr + activeEnergyKcal + TEF.value(mode: tefMode, intakeKcal: intakeKcal, macros: macros)
    }

    /// Positive = surplus (bulk), negative = deficit.
    public static func balance(intakeKcal: Double, tdee: Double) -> Double {
        intakeKcal - tdee
    }
}
