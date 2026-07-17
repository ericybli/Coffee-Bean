import XCTest
@testable import CoffeeBeanCore

final class OFFSearchTests: XCTestCase {
    private func fixture(_ name: String) throws -> Data {
        let url = Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures")!
        return try Data(contentsOf: url)
    }

    func testSearchURLEncodesQueryAndAsksForJSON() {
        let client = OpenFoodFactsClient(
            userAgent: "CoffeeBean/1.0 (engineering@month2month.com)")
        let s = client.searchURL(query: "peanut butter", pageSize: 20).absoluteString
        XCTAssertTrue(s.hasPrefix("https://world.openfoodfacts.org/cgi/search.pl"))
        XCTAssertTrue(s.contains("search_terms=peanut%20butter"))
        XCTAssertTrue(s.contains("json=1"))
        XCTAssertTrue(s.contains("page_size=20"))
        XCTAssertTrue(s.contains("fields="))
    }

    func testParseSearchKeepsOnlyUsableProducts() throws {
        let r = try JSONDecoder().decode(OFFSearchResponse.self, from: fixture("off_search_chicken"))
        let foods = OpenFoodFactsParser.parseSearch(r)

        // 4 products: one full, one kJ-only (string), one without energy (dropped),
        // one without a name (dropped).
        XCTAssertEqual(foods.count, 2)

        XCTAssertEqual(foods[0].name, "Grilled Chicken Breast")
        XCTAssertEqual(foods[0].barcode, "0001")
        XCTAssertEqual(foods[0].brand, "Tyson")
        XCTAssertEqual(foods[0].kcalPer100g, 165)
        XCTAssertEqual(foods[0].proteinPer100g, 31)
        XCTAssertEqual(foods[0].servingSizeText, "100 g")

        XCTAssertEqual(foods[1].name, "Chicken Breast Strips")
        XCTAssertEqual(foods[1].kcalPer100g, 690.0 / 4.184, accuracy: 0.1)
    }
}
