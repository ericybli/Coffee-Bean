import SwiftUI
import Charts
import CoffeeBeanCore

/// Raw weigh-ins as faint dots + a bold monotone trend line (never overshooting splines).
struct WeightTrendChart: View {
    let points: [TrendPoint]

    var body: some View {
        Chart {
            ForEach(points, id: \.date) { p in
                if let raw = p.rawAverage {
                    PointMark(x: .value("Date", p.date), y: .value("Weight", raw))
                        .foregroundStyle(Theme.textSecondary.opacity(0.45))
                        .symbolSize(16)
                }
            }
            ForEach(points, id: \.date) { p in
                LineMark(x: .value("Date", p.date), y: .value("Trend", p.trend))
                    .foregroundStyle(Theme.accent)
                    .interpolationMethod(.monotone)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
            }
        }
        .chartYScale(domain: .automatic(includesZero: false))
        .chartXAxis { AxisMarks(values: .automatic(desiredCount: 4)) }
        .frame(height: 200)
    }
}
