import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public struct OpenFoodFactsClient: FoodSource {
    public static let productionBaseURL = URL(string: "https://world.openfoodfacts.org")!
    public static let stagingBaseURL = URL(string: "https://world.openfoodfacts.net")!

    private static let fields = [
        "code", "product_name", "brands", "serving_size", "serving_quantity",
        "nutriments", "nutrition_data_per", "image_front_small_url"
    ].joined(separator: ",")

    let baseURL: URL
    let userAgent: String
    let session: URLSession

    public init(baseURL: URL = OpenFoodFactsClient.productionBaseURL,
                userAgent: String,
                session: URLSession = .shared) {
        self.baseURL = baseURL
        self.userAgent = userAgent
        self.session = session
    }

    public func productURL(barcode: String) -> URL {
        var comps = URLComponents(url: baseURL.appendingPathComponent("api/v2/product/\(barcode)"),
                                  resolvingAgainstBaseURL: false)!
        comps.queryItems = [URLQueryItem(name: "fields", value: Self.fields)]
        return comps.url!
    }

    public func lookup(barcode: String) async throws -> RemoteFood? {
        var request = URLRequest(url: productURL(barcode: barcode))
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, http.statusCode == 404 { return nil }
        let decoded = try JSONDecoder().decode(OFFResponse.self, from: data)
        return OpenFoodFactsParser.parse(decoded, barcode: barcode)
    }
}
