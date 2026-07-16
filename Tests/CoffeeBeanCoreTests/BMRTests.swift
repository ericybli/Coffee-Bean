import XCTest
@testable import CoffeeBeanCore

final class BMRTests: XCTestCase {
    func testMifflinMale() {
        // 80kg, 180cm, 30y, male: 10*80 + 6.25*180 - 5*30 + 5 = 800 + 1125 - 150 + 5 = 1780
        let b = Biometrics(weightKg: 80, heightCm: 180, ageYears: 30, sex: .male,
                           bodyFatFraction: nil, leanMassKg: nil)
        XCTAssertEqual(BMR.mifflinStJeor(b), 1780, accuracy: 1e-6)
    }
    func testMifflinFemale() {
        // 65kg, 165cm, 30y, female: 650 + 1031.25 - 150 - 161 = 1370.25
        let b = Biometrics(weightKg: 65, heightCm: 165, ageYears: 30, sex: .female,
                           bodyFatFraction: nil, leanMassKg: nil)
        XCTAssertEqual(BMR.mifflinStJeor(b), 1370.25, accuracy: 1e-6)
    }
    func testKatchMcArdle() {
        // lean 60kg: 370 + 21.6*60 = 370 + 1296 = 1666
        XCTAssertEqual(BMR.katchMcArdle(leanMassKg: 60), 1666, accuracy: 1e-6)
    }
}
