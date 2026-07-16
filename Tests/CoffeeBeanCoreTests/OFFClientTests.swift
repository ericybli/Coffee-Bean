import XCTest
@testable import CoffeeBeanCore

final class OFFClientTests: XCTestCase {
    func testProductURLIncludesFieldsAndBarcode() {
        let client = OpenFoodFactsClient(
            baseURL: OpenFoodFactsClient.productionBaseURL,
            userAgent: "CoffeeBean/1.0 (engineering@month2month.com)")
        let url = client.productURL(barcode: "3017624010701")
        let s = url.absoluteString
        XCTAssertTrue(s.hasPrefix("https://world.openfoodfacts.org/api/v2/product/3017624010701"))
        XCTAssertTrue(s.contains("fields="))
        XCTAssertTrue(s.contains("energy-kcal_100g") || s.contains("nutriments"))
    }
    func testStagingBaseURL() {
        XCTAssertEqual(OpenFoodFactsClient.stagingBaseURL.absoluteString,
                       "https://world.openfoodfacts.net")
    }
}
