import Foundation
import CoffeeBeanCore

/// Derives the smoothed trend, weekly rate, and BMI from raw weigh-ins via CoffeeBeanCore.
struct BodyMetrics {
    let trend: [TrendPoint]
    let currentTrendKg: Double?
    let weeklyRateKg: Double?
    let bmi: Double?

    /// α = 0.28 per the design handoff (more responsive than the research default 0.1).
    init(weights: [WeightEntry], heightCm: Double?, alpha: Double = 0.28) {
        let engine = TrendEngine(alpha: alpha)
        let weighIns = weights.map { WeighIn(date: $0.date, massKg: $0.massKg) }
        let t = engine.trend(from: weighIns)
        trend = t
        currentTrendKg = t.last?.trend
        weeklyRateKg = t.count >= 2 ? engine.weeklyRateKg(trend: t) : nil
        if let latest = t.last?.trend, let h = heightCm, h > 0 {
            let m = h / 100
            bmi = latest / (m * m)
        } else {
            bmi = nil
        }
    }
}
