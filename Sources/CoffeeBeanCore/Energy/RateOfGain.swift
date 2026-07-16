import Foundation

public enum RateBand: Sendable { case onTrack, slightlyFast, tooFast }

public enum RateOfGain {
    /// Lean-bulk guardrail on weekly bodyweight change (%BW/week).
    /// on-track 0.25–0.5, slightly fast 0.5–0.75, too fast > 0.75.
    public static func classify(weeklyRatePercentBW rate: Double) -> RateBand {
        if rate > 0.75 { return .tooFast }
        if rate > 0.5 { return .slightlyFast }
        return .onTrack
    }
}
