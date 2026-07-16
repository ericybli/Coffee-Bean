import XCTest
@testable import CoffeeBeanCore

final class RMRResolverTests: XCTestCase {
    private func base(lean: Double?) -> Biometrics {
        Biometrics(weightKg: 80, heightCm: 180, ageYears: 30, sex: .male,
                   bodyFatFraction: lean.map { _ in 0.15 }, leanMassKg: lean)
    }
    func testPrefersMeasuredDexaRMR() {
        let r = RMRResolver.resolve(biometrics: base(lean: 68), measuredRMR: 1720)
        XCTAssertEqual(r, RMRResult(value: 1720, source: .dexaMeasured))
    }
    func testFallsBackToKatchWhenLeanMassPresent() {
        let r = RMRResolver.resolve(biometrics: base(lean: 68), measuredRMR: nil)
        XCTAssertEqual(r.source, .katchMcArdle)
        XCTAssertEqual(r.value, 370 + 21.6 * 68, accuracy: 1e-6)
    }
    func testFallsBackToMifflinWhenNoDexa() {
        let r = RMRResolver.resolve(biometrics: base(lean: nil), measuredRMR: nil)
        XCTAssertEqual(r.source, .mifflinStJeor)
        XCTAssertEqual(r.value, 1780, accuracy: 1e-6)
    }
}
