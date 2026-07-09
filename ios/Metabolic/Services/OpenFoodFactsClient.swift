import Foundation
import MetabolicCore

/// Thin client over the public OpenFoodFacts API — barcode lookups, free-text food search
/// (used by `FoodSearchView`), and same-category alternative products (used by the scanner).
/// Every method degrades gracefully on network failure so callers never need to special-case
/// connectivity loss.
final class OpenFoodFactsClient {
    private let session: URLSession
    private let userAgent = "Metabolic-iOS/1.0 (hello@metabolicstudio.app)"

    private static let productFields =
        "code,product_name,brands,image_front_url,nutriments,additives_tags,labels_tags,categories_tags,nova_group"

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 15
        session = URLSession(configuration: config)
    }

    // MARK: - Product lookup

    func product(barcode: String) async throws -> ScannedProduct? {
        guard let url = URL(
            string: "https://world.openfoodfacts.org/api/v2/product/\(barcode).json?fields=\(Self.productFields)"
        ) else {
            return nil
        }
        let (data, _) = try await session.data(for: request(for: url))
        guard
            let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let status = root["status"] as? Int, status == 1,
            let product = root["product"] as? [String: Any]
        else {
            return nil
        }
        return Self.parseProduct(product, barcode: barcode)
    }

    // MARK: - Free-text search

    func searchFoods(query: String) async throws -> [FoodItem] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed
        guard let url = URL(
            string: "https://world.openfoodfacts.org/cgi/search.pl?search_terms=\(encoded)"
                + "&search_simple=1&action=process&json=1&page_size=20&fields=code,product_name,brands,nutriments"
        ) else {
            return []
        }

        do {
            let (data, _) = try await session.data(for: request(for: url))
            guard
                let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                let products = root["products"] as? [[String: Any]]
            else {
                return []
            }
            return products.compactMap(Self.parseFoodItem)
        } catch {
            return []
        }
    }

    // MARK: - Category alternatives

    func alternatives(categories: [String], excludingBarcode: String) async throws -> [(ScannedProduct, ProductScore)] {
        guard let tag = categories.last else { return [] }
        let encodedTag = tag.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? tag
        guard let url = URL(
            string: "https://world.openfoodfacts.org/api/v2/search?categories_tags=\(encodedTag)"
                + "&page_size=24&fields=\(Self.productFields)"
        ) else {
            return []
        }

        do {
            let (data, _) = try await session.data(for: request(for: url))
            guard
                let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                let products = root["products"] as? [[String: Any]]
            else {
                return []
            }
            let scored: [(ScannedProduct, ProductScore)] = products.compactMap { raw in
                guard let barcode = raw["code"] as? String, barcode != excludingBarcode else { return nil }
                guard let scannedProduct = Self.parseProduct(raw, barcode: barcode) else { return nil }
                return (scannedProduct, ProductScoringEngine.score(scannedProduct))
            }
            return Array(
                scored
                    .filter { $0.1.value >= 50 }
                    .sorted { $0.1.value > $1.1.value }
                    .prefix(6)
            )
        } catch {
            return []
        }
    }

    // MARK: - Request building

    private func request(for url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        return request
    }

    // MARK: - Parsing

    private static func nutrimentDouble(_ nutriments: [String: Any], _ key: String) -> Double? {
        if let value = nutriments[key] as? Double { return value }
        if let value = nutriments[key] as? Int { return Double(value) }
        if let value = nutriments[key] as? String { return Double(value) }
        return nil
    }

    private static func parseProduct(_ raw: [String: Any], barcode: String) -> ScannedProduct? {
        let name = (raw["product_name"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? "Unknown product"
        let brand = raw["brands"] as? String
        let imageURL = raw["image_front_url"] as? String
        let nutriments = raw["nutriments"] as? [String: Any] ?? [:]

        let sodiumMg: Double?
        if let sodiumG = nutrimentDouble(nutriments, "sodium_100g") {
            sodiumMg = sodiumG * 1000
        } else if let saltG = nutrimentDouble(nutriments, "salt_100g") {
            sodiumMg = saltG * 400
        } else {
            sodiumMg = nil
        }

        let additivesTags = raw["additives_tags"] as? [String] ?? []
        let additives = additivesTags.map { $0.hasPrefix("en:") ? String($0.dropFirst(3)) : $0 }

        let labelsTags = raw["labels_tags"] as? [String] ?? []
        let isOrganic = labelsTags.contains("en:organic")

        let categoriesTags = raw["categories_tags"] as? [String] ?? []
        let beverageCategories: Set<String> = ["en:beverages", "en:sodas", "en:juices", "en:waters"]
        let isBeverage = !beverageCategories.isDisjoint(with: Set(categoriesTags))

        return ScannedProduct(
            barcode: barcode,
            name: name,
            brand: brand,
            imageURLString: imageURL,
            isBeverage: isBeverage,
            isOrganic: isOrganic,
            energyKcal: nutrimentDouble(nutriments, "energy-kcal_100g"),
            sugarsG: nutrimentDouble(nutriments, "sugars_100g"),
            satFatG: nutrimentDouble(nutriments, "saturated-fat_100g"),
            sodiumMg: sodiumMg,
            fiberG: nutrimentDouble(nutriments, "fiber_100g"),
            proteinG: nutrimentDouble(nutriments, "proteins_100g"),
            fruitVegPercent: nutrimentDouble(nutriments, "fruits-vegetables-nuts-estimate-from-ingredients_100g"),
            additives: additives,
            categories: categoriesTags
        )
    }

    private static func parseFoodItem(_ raw: [String: Any]) -> FoodItem? {
        guard
            let code = raw["code"] as? String, !code.isEmpty,
            let name = raw["product_name"] as? String, !name.isEmpty
        else {
            return nil
        }
        let nutriments = raw["nutriments"] as? [String: Any] ?? [:]
        guard let calories = nutrimentDouble(nutriments, "energy-kcal_100g") else { return nil }

        let rawBrand = (raw["brands"] as? String)?
            .components(separatedBy: ",")
            .first?
            .trimmingCharacters(in: .whitespaces)
        let brand = (rawBrand?.isEmpty ?? true) ? nil : rawBrand

        return FoodItem(
            id: code,
            name: name,
            brand: brand,
            servingDescription: "per 100 g",
            calories: calories,
            proteinG: nutrimentDouble(nutriments, "proteins_100g") ?? 0,
            carbsG: nutrimentDouble(nutriments, "carbohydrates_100g") ?? 0,
            fatG: nutrimentDouble(nutriments, "fat_100g") ?? 0
        )
    }
}
