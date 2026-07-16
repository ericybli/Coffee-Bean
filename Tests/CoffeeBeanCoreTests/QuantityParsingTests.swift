import XCTest
@testable import CoffeeBeanCore

final class QuantityParsingTests: XCTestCase {
    func testInitFromImperialBodyMass() {
        let q = Quantity(displayValue: 160, kind: .bodyMass, system: .imperial)!
        XCTAssertEqual(q.canonicalValue, 72.5748, accuracy: 0.001) // 160 * 0.45359237
    }
    func testInitFromMetricVolume() {
        let q = Quantity(displayValue: 500, kind: .volume, system: .metric)!
        XCTAssertEqual(q.canonicalValue, 500, accuracy: 1e-9)
    }
    func testHeightCompositeExact() {
        let q = Quantity(canonicalValue: 180.34, kind: .height) // 71 in = 5 ft 11 in
        XCTAssertEqual(q.heightFeetInches(), FeetInches(feet: 5, inches: 11))
    }
    func testHeightCompositeCarryToNextFoot() {
        // 182.7 cm = 71.93 in -> rounds to 72 in -> must carry to 6 ft 0 in
        let q = Quantity(canonicalValue: 182.7, kind: .height)
        XCTAssertEqual(q.heightFeetInches(), FeetInches(feet: 6, inches: 0))
    }
}
