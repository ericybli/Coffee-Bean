import XCTest
@testable import CoffeeBeanCore

final class OFFParserTests: XCTestCase {
    private func fixture(_ name: String) throws -> OFFResponse {
        let url = Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures")!
        return try JSONDecoder().decode(OFFResponse.self, from: Data(contentsOf: url))
    }
    func testParsesNutella() throws {
        let food = OpenFoodFactsParser.parse(try fixture("off_nutella"), barcode: "3017624010701")!
        XCTAssertEqual(food.name, "Nutella")
        XCTAssertEqual(food.kcalPer100g, 539, accuracy: 1e-6)
        XCTAssertEqual(food.proteinPer100g, 6.3, accuracy: 1e-6)
    }
    func testDerivesKcalFromKJ() throws {
        // 1000 kJ / 4.184 = 239.006 kcal
        let food = OpenFoodFactsParser.parse(try fixture("off_kj_only"), barcode: "1111111111111")!
        XCTAssertEqual(food.kcalPer100g, 239.006, accuracy: 0.01)
    }
    func testNilWhenNotFound() {
        let r = OFFResponse.notFound(code: "000")
        XCTAssertNil(OpenFoodFactsParser.parse(r, barcode: "000"))
    }
    func testNilWhenNoUsableEnergy() {
        let r = OFFResponse.placeholder(name: "Empty", code: "999") // name but no nutriments
        XCTAssertNil(OpenFoodFactsParser.parse(r, barcode: "999"))
    }
}

// Test-only builders for synthetic responses.
extension OFFResponse {
    static func notFound(code: String) -> OFFResponse {
        try! JSONDecoder().decode(OFFResponse.self,
            from: Data(#"{"status":0,"code":"\#(code)"}"#.utf8))
    }
    static func placeholder(name: String, code: String) -> OFFResponse {
        try! JSONDecoder().decode(OFFResponse.self,
            from: Data(#"{"status":1,"code":"\#(code)","product":{"product_name":"\#(name)","nutriments":{}}}"#.utf8))
    }
}
