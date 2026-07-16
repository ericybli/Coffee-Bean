import XCTest
@testable import CoffeeBeanCore

final class EnergyBalanceTests: XCTestCase {
    func testStaticTDEEFlatTEF() {
        // rmr 1780 + active 500 + TEF(flat 10% of 2500 intake)=250 => 2530
        let tdee = EnergyBalance.staticTDEE(rmr: 1780, activeEnergyKcal: 500,
                                            intakeKcal: 2500, macros: nil, tefMode: .flatTen)
        XCTAssertEqual(tdee, 2530, accuracy: 1e-6)
    }
    func testBalanceSurplusIsPositive() {
        let b = EnergyBalance.balance(intakeKcal: 2800, tdee: 2530)
        XCTAssertEqual(b, 270, accuracy: 1e-6) // surplus
    }
    func testBalanceDeficitIsNegative() {
        let b = EnergyBalance.balance(intakeKcal: 2200, tdee: 2530)
        XCTAssertEqual(b, -330, accuracy: 1e-6)
    }
}
