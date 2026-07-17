import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// USDA FoodData Central search — the authority for generic/unpackaged foods
/// ("chicken breast, cooked") that Open Food Facts covers poorly.
/// Free API keys at https://fdc.nal.usda.gov/api-key-signup ; DEMO_KEY works
/// for light personal use (30 requests/hour per IP).
public struct USDAClient {
    public static let productionBaseURL = URL(string: "https://api.nal.usda.gov")!
    public static let demoKey = "DEMO_KEY"

    /// Generic-food datasets only: lab-analyzed (Foundation) and the classic
    /// USDA reference DB (SR Legacy). Values are per 100 g.
    static let dataTypes = "Foundation,SR Legacy"

    let baseURL: URL
    let apiKey: String
    let session: URLSession

    public init(baseURL: URL = USDAClient.productionBaseURL,
                apiKey: String = USDAClient.demoKey,
                session: URLSession = .shared) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.session = session
    }

    public func searchURL(query: String, pageSize: Int = 20) -> URL {
        var comps = URLComponents(url: baseURL.appendingPathComponent("fdc/v1/foods/search"),
                                  resolvingAgainstBaseURL: false)!
        comps.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "dataType", value: Self.dataTypes),
            URLQueryItem(name: "pageSize", value: String(pageSize))
        ]
        return comps.url!
    }

    public func search(query: String, pageSize: Int = 20) async throws -> [RemoteFood] {
        let (data, _) = try await session.data(from: searchURL(query: query, pageSize: pageSize))
        let decoded = try JSONDecoder().decode(USDASearchResponse.self, from: data)
        return USDAParser.parse(decoded)
    }
}

public enum USDAParser {
    /// Normalize a search page, dropping foods without a name or energy value
    /// and duplicate names (FDC lists the same food across datasets).
    /// FDC nutrient numbers: 208 energy kcal, 203 protein, 205 carbs, 204 fat.
    public static func parse(_ response: USDASearchResponse) -> [RemoteFood] {
        var seenNames = Set<String>()
        return response.foods.compactMap { f in
            guard let name = f.description,
                  seenNames.insert(name.lowercased()).inserted else { return nil }
            return parseFood(f)
        }
    }

    private static func parseFood(_ f: USDAFood) -> RemoteFood? {
        guard let name = f.description, !name.isEmpty else { return nil }
        let byNumber = Dictionary(f.foodNutrients.compactMap { n in
            n.nutrientNumber.flatMap { num in n.value.map { (num, $0) } }
        }, uniquingKeysWith: { first, _ in first })
        guard let kcal = byNumber["208"] else { return nil }
        return RemoteFood(
            barcode: f.gtinUpc,
            name: name,
            brand: f.brandOwner,
            kcalPer100g: kcal,
            proteinPer100g: byNumber["203"] ?? 0,
            carbPer100g: byNumber["205"] ?? 0,
            fatPer100g: byNumber["204"] ?? 0,
            servingSizeText: nil,
            imageURL: nil
        )
    }
}
