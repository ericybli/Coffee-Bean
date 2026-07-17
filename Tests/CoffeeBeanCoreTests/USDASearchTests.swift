import XCTest
@testable import CoffeeBeanCore

final class USDASearchTests: XCTestCase {
    private func fixture(_ name: String) throws -> Data {
        let url = Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures")!
        return try Data(contentsOf: url)
    }

    func testSearchURLIncludesKeyQueryAndDataTypes() {
        let client = USDAClient(apiKey: "TEST_KEY")
        let s = client.searchURL(query: "brown rice cooked", pageSize: 15).absoluteString
        XCTAssertTrue(s.hasPrefix("https://api.nal.usda.gov/fdc/v1/foods/search"))
        XCTAssertTrue(s.contains("api_key=TEST_KEY"))
        XCTAssertTrue(s.contains("query=brown%20rice%20cooked"))
        XCTAssertTrue(s.contains("dataType=Foundation,SR%20Legacy"))
        XCTAssertTrue(s.contains("pageSize=15"))
    }

    func testParseKeepsOnlyFoodsWithEnergy() throws {
        let r = try JSONDecoder().decode(USDASearchResponse.self, from: fixture("usda_search_chicken"))
        let foods = USDAParser.parse(r)

        // 3 foods: full SR Legacy, one without energy (dropped), one branded.
        XCTAssertEqual(foods.count, 2)

        XCTAssertEqual(foods[0].name, "Chicken, broilers or fryers, breast, meat only, cooked, roasted")
        XCTAssertNil(foods[0].brand)
        XCTAssertNil(foods[0].barcode)
        XCTAssertEqual(foods[0].kcalPer100g, 165)
        XCTAssertEqual(foods[0].proteinPer100g, 31.0)
        XCTAssertEqual(foods[0].carbPer100g, 0.0)
        XCTAssertEqual(foods[0].fatPer100g, 3.57)

        XCTAssertEqual(foods[1].name, "GRILLED CHICKEN BREAST STRIPS")
        XCTAssertEqual(foods[1].brand, "Tyson Foods Inc.")
        XCTAssertEqual(foods[1].barcode, "023700043177")
        XCTAssertEqual(foods[1].kcalPer100g, 106)
        // Missing macros default to 0, never nil-crash.
        XCTAssertEqual(foods[1].carbPer100g, 0)
    }

    func testParseDropsDuplicateNames() throws {
        let r = try JSONDecoder().decode(USDASearchResponse.self, from: fixture("usda_search_chicken"))
        let doubled = USDASearchResponse(totalHits: 6, foods: r.foods + r.foods)
        XCTAssertEqual(USDAParser.parse(doubled).count, 2)
    }
}
