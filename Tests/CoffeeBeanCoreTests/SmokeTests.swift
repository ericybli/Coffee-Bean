import XCTest
@testable import CoffeeBeanCore

final class SmokeTests: XCTestCase {
    func testVersionIsSet() {
        XCTAssertEqual(CoffeeBeanCore.version, "0.1.0")
    }
}
