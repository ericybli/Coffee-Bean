import SwiftUI
import Charts
import CoffeeBeanCore

/// Raw measurements as faint dots + a bold monotone trend line (never overshooting splines).
struct WeightTrendChart: View {
    let points: [TrendPoint]
    var color: Color = Theme.accent
    var height: CGFloat = 200

    var body: some View {
        Chart {
            ForEach(points, id: \.date) { p in
                if let raw = p.rawAverage {
                    PointMark(x: .value("Date", p.date), y: .value("Value", raw))
                        .foregroundStyle(Theme.textSecondary.opacity(0.45))
                        .symbolSize(16)
                }
            }
            ForEach(points, id: \.date) { p in
                LineMark(x: .value("Date", p.date), y: .value("Trend", p.trend))
                    .foregroundStyle(color)
                    .interpolationMethod(.monotone)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
            }
        }
        .chartYScale(domain: .automatic(includesZero: false))
        .chartXAxis { AxisMarks(values: .automatic(desiredCount: 4)) }
        .frame(height: height)
    }
}
