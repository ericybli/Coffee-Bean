import XCTest
@testable import CoffeeBeanCore

final class AdaptiveTDEETests: XCTestCase {
    func testMaintenanceGainMeansSurplus() {
        // gained 0.5 kg over 14 days on mean intake 2800:
        // maintenance = 2800 - 7700*0.5/14 = 2800 - 275 = 2525 (< intake => was in surplus)
        let m = AdaptiveTDEE.maintenance(meanIntakeKcal: 2800, trendStartKg: 72.0,
                                         trendEndKg: 72.5, windowDays: 14)
        XCTAssertEqual(m, 2525, accuracy: 1e-6)
    }
    func testMaintenanceLossMeansDeficit() {
        // lost 0.5 kg over 14 days on mean intake 2200:
        // maintenance = 2200 - 7700*(-0.5)/14 = 2200 + 275 = 2475 (> intake => was in deficit)
        let m = AdaptiveTDEE.maintenance(meanIntakeKcal: 2200, trendStartKg: 72.5,
                                         trendEndKg: 72.0, windowDays: 14)
        XCTAssertEqual(m, 2475, accuracy: 1e-6)
    }
    func testTrustworthyGating() {
        let ok = AdaptiveTDEE.evaluate(meanIntakeKcal: 2800, trendStartKg: 72, trendEndKg: 72.5,
                                       windowDays: 14, daysLogged: 20, weighIns: 12)
        XCTAssertTrue(ok.isTrustworthy)
        let notYet = AdaptiveTDEE.evaluate(meanIntakeKcal: 2800, trendStartKg: 72, trendEndKg: 72.5,
                                           windowDays: 14, daysLogged: 5, weighIns: 3)
        XCTAssertFalse(notYet.isTrustworthy)
    }
    func testDexaReconciliation() {
        // adaptive 2530, DEXA RMR 1720 -> multiplier 1.4709; active = 2530-1720-250 = 560
        XCTAssertEqual(AdaptiveTDEE.impliedActivityMultiplier(adaptiveTDEE: 2530, rmr: 1720),
                       1.47093, accuracy: 0.001)
        XCTAssertEqual(AdaptiveTDEE.impliedActiveEnergy(adaptiveTDEE: 2530, rmr: 1720, tefKcal: 250),
                       560, accuracy: 1e-6)
    }
}
