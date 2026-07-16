import XCTest
@testable import CoffeeBeanCore

final class TargetTests: XCTestCase {
    func testCalorieTargetFixed() {
        XCTAssertEqual(CalorieTarget.fixed(2610).resolve(tdee: 2460), 2610, accuracy: 1e-6)
    }
    func testCalorieTargetTDEEOffset() {
        XCTAssertEqual(CalorieTarget.tdeeOffset(150).resolve(tdee: 2460), 2610, accuracy: 1e-6)
    }
    func testDefaultSplitGrams() {
        // Default 50/30/20 C/F/P of 2000 kcal: C=1000/4=250, F=600/9=66.67, P=400/4=100
        let m = MacroSplit.default.grams(forCalories: 2000)
        XCTAssertEqual(m.carbG, 250, accuracy: 1e-6)
        XCTAssertEqual(m.fatG, 66.6667, accuracy: 0.001)
        XCTAssertEqual(m.proteinG, 100, accuracy: 1e-6)
    }
    func testCustomProteinAutoFills() {
        // custom carbs 40, fat 20 => protein auto = 40
        let s = MacroSplit.custom(carbPct: 40, fatPct: 20)
        XCTAssertEqual(s.proteinPct, 40, accuracy: 1e-6)
    }
    func testRateOfGainBands() {
        XCTAssertEqual(RateOfGain.classify(weeklyRatePercentBW: 0.35), .onTrack)
        XCTAssertEqual(RateOfGain.classify(weeklyRatePercentBW: 0.65), .slightlyFast)
        XCTAssertEqual(RateOfGain.classify(weeklyRatePercentBW: 1.2), .tooFast)
    }
}
