import XCTest
@testable import CoffeeBeanCore

final class QuantityConversionTests: XCTestCase {
    func testBodyMassKgToLb() {
        let q = Quantity(canonicalValue: 72.4, kind: .bodyMass)
        XCTAssertEqual(q.value(in: .metric), 72.4, accuracy: 1e-9)
        XCTAssertEqual(q.value(in: .imperial), 159.615, accuracy: 0.01) // 72.4 / 0.45359237
    }
    func testFoodMassGToOz() {
        let q = Quantity(canonicalValue: 100, kind: .foodMass)
        XCTAssertEqual(q.value(in: .imperial), 3.5274, accuracy: 0.001) // 100 / 28.349523125
    }
    func testVolumeMlToUSFlOz() {
        let q = Quantity(canonicalValue: 500, kind: .volume)
        XCTAssertEqual(q.value(in: .imperial), 16.907, accuracy: 0.01) // 500 / 29.5735295625
    }
    func testHeightCmToInches() {
        let q = Quantity(canonicalValue: 180, kind: .height)
        XCTAssertEqual(q.value(in: .imperial), 70.866, accuracy: 0.01) // 180 / 2.54
    }
    func testEnergyIsSameBothSystems() {
        let q = Quantity(canonicalValue: 2460, kind: .energy)
        XCTAssertEqual(q.value(in: .metric), 2460, accuracy: 1e-9)
        XCTAssertEqual(q.value(in: .imperial), 2460, accuracy: 1e-9)
    }
}
