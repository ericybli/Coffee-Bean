import XCTest
@testable import CoffeeBeanCore

final class TrendEWMATests: XCTestCase {
    // Fixed UTC calendar + day helper for deterministic dates.
    private var cal: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }
    private func day(_ n: Int) -> Date {
        cal.date(from: DateComponents(year: 2026, month: 1, day: n))!
    }

    func testEWMAKnownSequence() {
        // alpha 0.5, weights 100 then 102: T0=100, T1=100+0.5*(102-100)=101
        let engine = TrendEngine(alpha: 0.5, calendar: cal)
        let points = engine.trend(from: [
            WeighIn(date: day(1), massKg: 100),
            WeighIn(date: day(2), massKg: 102),
        ])
        XCTAssertEqual(points.map(\.trend), [100, 101])
    }

    func testCollapsesMultiplePerDay() {
        // two weigh-ins same day -> averaged before smoothing
        let engine = TrendEngine(alpha: 1.0, calendar: cal) // alpha 1 -> trend == raw avg
        let points = engine.trend(from: [
            WeighIn(date: day(1), massKg: 100),
            WeighIn(date: day(1), massKg: 102),
        ])
        XCTAssertEqual(points.count, 1)
        XCTAssertEqual(points[0].rawAverage, 101)
        XCTAssertEqual(points[0].trend, 101)
    }

    func testGapInterpolation() {
        // day1=100, day3=104, day2 missing -> interpolated raw 102. alpha 1 -> trend follows interpolation.
        let engine = TrendEngine(alpha: 1.0, calendar: cal)
        let points = engine.trend(from: [
            WeighIn(date: day(1), massKg: 100),
            WeighIn(date: day(3), massKg: 104),
        ])
        XCTAssertEqual(points.count, 3)
        XCTAssertNil(points[1].rawAverage)          // day 2 had no weigh-in
        XCTAssertEqual(points[1].trend, 102)        // interpolated into the smoother
        XCTAssertEqual(points[2].trend, 104)
    }
}
