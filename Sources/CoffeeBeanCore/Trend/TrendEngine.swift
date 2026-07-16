import Foundation

public struct TrendEngine {
    public let alpha: Double
    public var calendar: Calendar

    public init(alpha: Double = 0.1, calendar: Calendar = TrendEngine.utcCalendar) {
        self.alpha = alpha
        self.calendar = calendar
    }

    public static var utcCalendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }

    /// Smoothed trend over a per-calendar-day grid, gaps linearly interpolated.
    public func trend(from weighIns: [WeighIn]) -> [TrendPoint] {
        guard !weighIns.isEmpty else { return [] }

        // 1. Collapse to one average per calendar day.
        var byDay: [Date: [Double]] = [:]
        for w in weighIns {
            let d = calendar.startOfDay(for: w.date)
            byDay[d, default: []].append(w.massKg)
        }
        let sortedDays = byDay.keys.sorted()
        let firstDay = sortedDays.first!
        let lastDay = sortedDays.last!

        // 2. Build the continuous daily grid (raw average or nil).
        var grid: [(date: Date, raw: Double?)] = []
        var cursor = firstDay
        while cursor <= lastDay {
            if let vals = byDay[cursor] {
                grid.append((cursor, vals.reduce(0, +) / Double(vals.count)))
            } else {
                grid.append((cursor, nil))
            }
            cursor = calendar.date(byAdding: .day, value: 1, to: cursor)!
        }

        // 3. Linear-interpolate missing days between known values.
        let interpolated = linearInterpolate(grid.map(\.raw))

        // 4. EWMA recursion.
        var trends: [Double] = []
        var t = interpolated[0]
        for (i, value) in interpolated.enumerated() {
            if i == 0 { t = value } else { t += alpha * (value - t) }
            trends.append(t)
        }

        // 5. Assemble points (rawAverage stays nil on interpolated-only days).
        return grid.enumerated().map { i, g in
            TrendPoint(date: g.date, rawAverage: g.raw, trend: trends[i])
        }
    }

    /// Fill nils by linear interpolation between surrounding known values; edges hold nearest known.
    private func linearInterpolate(_ series: [Double?]) -> [Double] {
        let n = series.count
        var out = [Double](repeating: 0, count: n)
        var lastKnownIndex: Int? = nil
        for i in 0..<n {
            if let v = series[i] {
                out[i] = v
                if let last = lastKnownIndex, last < i - 1 {
                    let startV = out[last], endV = v
                    let span = i - last
                    for j in (last + 1)..<i {
                        let frac = Double(j - last) / Double(span)
                        out[j] = startV + (endV - startV) * frac
                    }
                }
                lastKnownIndex = i
            }
        }
        // Leading nils -> first known value.
        if let first = series.firstIndex(where: { $0 != nil }) {
            for i in 0..<first { out[i] = series[first]! }
        }
        return out
    }
}

public extension TrendEngine {
    /// Weekly rate of change (kg/week) = least-squares slope of the trend over the last `overLastDays` days × 7.
    func weeklyRateKg(trend: [TrendPoint], overLastDays: Int = 14) -> Double {
        let window = Array(trend.suffix(overLastDays))
        guard window.count >= 2 else { return 0 }
        let xs = window.indices.map(Double.init)              // day index 0..n-1
        let ys = window.map(\.trend)
        let n = Double(window.count)
        let sumX = xs.reduce(0, +), sumY = ys.reduce(0, +)
        let sumXY = zip(xs, ys).map(*).reduce(0, +)
        let sumXX = xs.map { $0 * $0 }.reduce(0, +)
        let denom = n * sumXX - sumX * sumX
        guard denom != 0 else { return 0 }
        let slopePerDay = (n * sumXY - sumX * sumY) / denom
        return slopePerDay * 7
    }

    /// Days to reach `goalKg` at the current weekly rate. nil if rate is zero or points the wrong way.
    func projectionDays(currentTrendKg: Double, goalKg: Double, weeklyRateKg: Double) -> Double? {
        guard weeklyRateKg != 0 else { return nil }
        let remaining = goalKg - currentTrendKg
        let perDay = weeklyRateKg / 7
        let days = remaining / perDay
        return days > 0 ? days : nil
    }

    /// True while the trend is still converging (fewer than `minDays` days of data ≈ 2 half-lives at α=0.1).
    func isWarmUp(trend: [TrendPoint], minDays: Int = 13) -> Bool {
        trend.count < minDays
    }
}
