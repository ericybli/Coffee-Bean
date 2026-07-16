import Foundation

public let kcalPerKg = 7700.0
public let kcalPerLb = kcalPerKg * 0.45359237   // derive; never hardcode 3500

public struct AdaptiveResult: Equatable, Sendable {
    public let maintenanceKcal: Double
    public let isTrustworthy: Bool
    public init(maintenanceKcal: Double, isTrustworthy: Bool) {
        self.maintenanceKcal = maintenanceKcal
        self.isTrustworthy = isTrustworthy
    }
}

public enum AdaptiveTDEE {
    /// Empirical maintenance from the energy-balance identity over a window.
    /// Gaining trend weight lowers maintenance below intake (you were in surplus).
    public static func maintenance(meanIntakeKcal: Double, trendStartKg: Double,
                                   trendEndKg: Double, windowDays: Int) -> Double {
        let deltaKg = trendEndKg - trendStartKg
        return meanIntakeKcal - kcalPerKg * deltaKg / Double(windowDays)
    }

    public static func evaluate(meanIntakeKcal: Double, trendStartKg: Double, trendEndKg: Double,
                                windowDays: Int, daysLogged: Int, weighIns: Int) -> AdaptiveResult {
        let m = maintenance(meanIntakeKcal: meanIntakeKcal, trendStartKg: trendStartKg,
                            trendEndKg: trendEndKg, windowDays: windowDays)
        return AdaptiveResult(maintenanceKcal: m, isTrustworthy: daysLogged >= 14 && weighIns >= 8)
    }

    /// DEXA reconciliation: treat RMR as the fixed resting anchor.
    public static func impliedActivityMultiplier(adaptiveTDEE: Double, rmr: Double) -> Double {
        guard rmr != 0 else { return 0 }
        return adaptiveTDEE / rmr
    }

    public static func impliedActiveEnergy(adaptiveTDEE: Double, rmr: Double, tefKcal: Double) -> Double {
        adaptiveTDEE - rmr - tefKcal
    }
}
