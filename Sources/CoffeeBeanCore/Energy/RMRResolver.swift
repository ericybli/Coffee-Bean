import Foundation

public enum RMRSource: String, Codable, Sendable {
    case dexaMeasured, katchMcArdle, mifflinStJeor
}

public struct RMRResult: Equatable, Sendable {
    public let value: Double
    public let source: RMRSource
    public init(value: Double, source: RMRSource) {
        self.value = value
        self.source = source
    }
}

public enum RMRResolver {
    /// Resolve RMR by source priority: measured DEXA > Katch-McArdle (DEXA lean mass) > Mifflin-St Jeor.
    public static func resolve(biometrics: Biometrics, measuredRMR: Double?) -> RMRResult {
        if let measured = measuredRMR {
            return RMRResult(value: measured, source: .dexaMeasured)
        }
        if let lean = biometrics.leanMassKg {
            return RMRResult(value: BMR.katchMcArdle(leanMassKg: lean), source: .katchMcArdle)
        }
        return RMRResult(value: BMR.mifflinStJeor(biometrics), source: .mifflinStJeor)
    }
}
