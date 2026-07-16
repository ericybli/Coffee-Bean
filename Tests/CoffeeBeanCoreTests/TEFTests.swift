import XCTest
@testable import CoffeeBeanCore

final class TEFTests: XCTestCase {
    func testMacrosKcal() {
        let m = Macros(proteinG: 200, carbG: 250, fatG: 70)
        XCTAssertEqual(m.kcal, 2430, accuracy: 1e-6) // 200*4 + 250*4 + 70*9 = 800+1000+630
    }
    func testFlatTenPercent() {
        XCTAssertEqual(TEF.value(mode: .flatTen, intakeKcal: 2500, macros: nil), 250, accuracy: 1e-6)
    }
    func testNoneIsZero() {
        XCTAssertEqual(TEF.value(mode: .none, intakeKcal: 2500, macros: nil), 0, accuracy: 1e-6)
    }
    func testPerMacro() {
        // P200g=800kcal*.25=200; C250g=1000*.08=80; F70g=630*.02=12.6 -> 292.6
        let m = Macros(proteinG: 200, carbG: 250, fatG: 70)
        XCTAssertEqual(TEF.value(mode: .perMacro, intakeKcal: m.kcal, macros: m), 292.6, accuracy: 1e-6)
    }
    func testPerMacroWithoutMacrosFallsBackToFlatTen() {
        XCTAssertEqual(TEF.value(mode: .perMacro, intakeKcal: 2500, macros: nil), 250, accuracy: 1e-6)
    }
}
