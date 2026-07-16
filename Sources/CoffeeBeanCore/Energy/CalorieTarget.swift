import Foundation

public enum CalorieTarget: Equatable, Sendable {
    case fixed(Double)
    case tdeeOffset(Double)   // + surplus / - deficit relative to TDEE

    public func resolve(tdee: Double) -> Double {
        switch self {
        case .fixed(let v): return v
        case .tdeeOffset(let d): return tdee + d
        }
    }
}
