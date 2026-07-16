import XCTest
@testable import CoffeeBeanCore

final class TrendRateTests: XCTestCase {
    private let engine = TrendEngine(alpha: 0.1, calendar: TrendEngine.utcCalendar)
    private func mkTrend(_ values: [Double]) -> [TrendPoint] {
        let cal = TrendEngine.utcCalendar
        return values.enumerated().map { i, v in
            TrendPoint(date: cal.date(from: DateComponents(year: 2026, month: 2, day: i + 1))!,
                       rawAverage: v, trend: v)
        }
    }
    func testWeeklyRateOnLinearTrend() {
        // +0.1 kg/day over 15 days -> 0.7 kg/week
        let t = mkTrend((0..<15).map { 70 + 0.1 * Double($0) })
        XCTAssertEqual(engine.weeklyRateKg(trend: t, overLastDays: 14), 0.7, accuracy: 1e-6)
    }
    func testProjectionDays() {
        // from 72 to 75 at 0.3 kg/wk -> 3 / (0.3/7) = 70 days
        let days = engine.projectionDays(currentTrendKg: 72, goalKg: 75, weeklyRateKg: 0.3)!
        XCTAssertEqual(days, 70, accuracy: 1e-6)
    }
    func testProjectionNilWhenRateZero() {
        XCTAssertNil(engine.projectionDays(currentTrendKg: 72, goalKg: 75, weeklyRateKg: 0))
    }
    func testProjectionNilWhenWrongDirection() {
        // goal above current but losing weight -> unreachable
        XCTAssertNil(engine.projectionDays(currentTrendKg: 72, goalKg: 75, weeklyRateKg: -0.2))
    }
    func testWarmUp() {
        XCTAssertTrue(engine.isWarmUp(trend: mkTrend(Array(repeating: 70, count: 10))))
        XCTAssertFalse(engine.isWarmUp(trend: mkTrend(Array(repeating: 70, count: 20))))
    }
}
