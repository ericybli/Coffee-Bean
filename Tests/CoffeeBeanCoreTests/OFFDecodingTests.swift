import XCTest
@testable import CoffeeBeanCore

final class OFFDecodingTests: XCTestCase {
    private func fixture(_ name: String) throws -> Data {
        let url = Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures")!
        return try Data(contentsOf: url)
    }
    func testDecodeNutella() throws {
        let r = try JSONDecoder().decode(OFFResponse.self, from: fixture("off_nutella"))
        XCTAssertEqual(r.status, 1)
        XCTAssertEqual(r.product?.productName, "Nutella")
        XCTAssertEqual(r.product?.nutriments["energy-kcal_100g"], 539)
        XCTAssertEqual(r.product?.nutriments["proteins_100g"], 6.3)
        XCTAssertEqual(r.product?.servingQuantity, 15)
    }
    func testDecodesNumericStrings() throws {
        // energy-kj as a String "1000", proteins as "5" -> must decode to Doubles
        let r = try JSONDecoder().decode(OFFResponse.self, from: fixture("off_kj_only"))
        XCTAssertEqual(r.product?.nutriments["energy-kj_100g"], 1000)
        XCTAssertEqual(r.product?.nutriments["proteins_100g"], 5)
    }
}
