//
//  USDANutritionService.swift
//  FoodTrackingApp
//
//  Survey-only USDA FoodData Central lookup
//

import Foundation

// MARK: - Public types

struct MacrosPer100g {
    let caloriesKcal: Double
    let proteinG: Double
    let carbsG: Double
    let fatG: Double
}

struct USDAFoodChoice {
    let fdcId: Int
    let description: String
    let dataType: String
}

// MARK: - Service

final class USDANutritionService {

    private let baseURL = URL(string: "https://api.nal.usda.gov/fdc/v1")!

    // Loaded via Info.plist key "FDC_API_KEY" -> $(FDC_API_KEY) from Secrets.xcconfig
    private let apiKey: String = {
        guard
            let v = Bundle.main.object(forInfoDictionaryKey: "FDC_API_KEY") as? String,
            !v.isEmpty
        else { return "" }
        return v
    }()

    // Energy (kcal) 1008, Protein 1003, Fat 1004, Carbs 1005
    private enum NutrientId: Int {
        case calories = 1008
        case protein  = 1003
        case fat      = 1004
        case carbs    = 1005
    }

    // MARK: - Public API (Survey-only)

    /// Survey-only: search Survey foods and return macros per 100g.
    /// Throws if no suitable result found.
    func fetchSurveyMacrosPer100g(query rawQuery: String) async throws -> (choice: USDAFoodChoice, macros: MacrosPer100g) {
        guard !apiKey.isEmpty else {
            throw NSError(domain: "USDANutritionService", code: 900,
                          userInfo: [NSLocalizedDescriptionKey: "Missing FDC_API_KEY (check Secrets.xcconfig + Info.plist)."])
        }

        let query = normalizeQuery(rawQuery)

        // Try both strings in case the API expects one or the other
        if let choice = try await searchBestMatch(query: query, dataTypes: ["Survey (FNDDS)"]) {
            let macros = try await fetchMacrosForFood(fdcId: choice.fdcId)
            return (choice, macros)
        }

        if let choice = try await searchBestMatch(query: query, dataTypes: ["Survey"]) {
            let macros = try await fetchMacrosForFood(fdcId: choice.fdcId)
            return (choice, macros)
        }

        throw NSError(domain: "USDANutritionService", code: 404,
                      userInfo: [NSLocalizedDescriptionKey: "No Survey (FNDDS) results found for: \(query)"])
    }

    // MARK: - Search

    private func searchBestMatch(query: String, dataTypes: [String]) async throws -> USDAFoodChoice? {
        let url = baseURL.appendingPathComponent("foods/search").appending(queryItems: [
            URLQueryItem(name: "api_key", value: apiKey)
        ])

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = FoodSearchRequest(
            query: query,
            dataType: dataTypes,
            pageSize: 25,
            pageNumber: 1
        )
        req.httpBody = try JSONEncoder().encode(body)

        let (data, resp) = try await URLSession.shared.data(for: req)
        try validateHTTP(resp)

        let decoded = try JSONDecoder().decode(FoodSearchResponse.self, from: data)
        guard let foods = decoded.foods, !foods.isEmpty else { return nil }

        // Choose best by token match scoring
        let best = foods
            .sorted { score(food: $0, query: query) > score(food: $1, query: query) }
            .first

        guard let bestFood = best else { return nil }

        // Optional: reject extremely low scores (prevents “fries -> fried rice” style jumps)
        if score(food: bestFood, query: query) < 5 {
            return nil
        }

        return USDAFoodChoice(
            fdcId: bestFood.fdcId,
            description: bestFood.description,
            dataType: bestFood.dataType
        )
    }

    /// Token-based scoring that heavily rewards matching query tokens,
    /// and penalizes missing tokens to avoid unrelated picks.
    private func score(food: FoodSearchFood, query: String) -> Int {
        let qNorm = normalizeQuery(query)
        let dNorm = normalizeQuery(food.description)

        let qTokens = Set(tokenize(qNorm))
        let dTokens = Set(tokenize(dNorm))

        // count overlaps
        let overlap = qTokens.intersection(dTokens).count
        let missing = qTokens.subtracting(dTokens).count

        var s = 0

        // strong rewards
        if dNorm == qNorm { s += 100 }
        if dNorm.hasPrefix(qNorm) { s += 40 }
        if dNorm.contains(qNorm) { s += 20 }

        // token overlap is king
        s += overlap * 15

        // missing tokens penalty (prevents “french fries” -> “fried rice”)
        s -= missing * 20

        // small penalty for long noisy descriptions
        s -= max(0, dTokens.count - 10)

        // penalize obvious brand/restaurant names unless the user typed them
        let badWords = ["mcdonald", "burger king", "wendy", "domino", "pizza hut", "taco bell", "kfc", "subway"]
        if badWords.contains(where: { dNorm.contains($0) }) && !badWords.contains(where: { qNorm.contains($0) }) {
            s -= 30
        }

        return s
    }

    // MARK: - Details (nutrients)

    private func fetchMacrosForFood(fdcId: Int) async throws -> MacrosPer100g {
        let url = baseURL
            .appendingPathComponent("food/\(fdcId)")
            .appending(queryItems: [
                URLQueryItem(name: "api_key", value: apiKey)
            ])

        var req = URLRequest(url: url)
        req.httpMethod = "GET"

        let (data, resp) = try await URLSession.shared.data(for: req)
        try validateHTTP(resp)

        let decoded = try JSONDecoder().decode(FoodDetailsResponse.self, from: data)
        let nutrients = decoded.foodNutrients ?? []

        func value(_ id: NutrientId) -> Double {
            if let match = nutrients.first(where: { ($0.nutrient?.id == id.rawValue) || ($0.foodNutrientId == id.rawValue) }) {
                return match.amount ?? 0
            }
            return 0
        }

        return MacrosPer100g(
            caloriesKcal: value(.calories),
            proteinG: value(.protein),
            carbsG: value(.carbs),
            fatG: value(.fat)
        )
    }

    // MARK: - Helpers

    private func normalizeQuery(_ s: String) -> String {
        s.lowercased()
            // convert underscores, punctuation, etc. to spaces
            .replacingOccurrences(of: "[^a-z0-9]+", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func tokenize(_ s: String) -> [String] {
        s.split(separator: " ").map { String($0) }.filter { !$0.isEmpty }
    }

    private func validateHTTP(_ resp: URLResponse) throws {
        guard let http = resp as? HTTPURLResponse else { return }
        if !(200...299).contains(http.statusCode) {
            throw NSError(domain: "USDANutritionService", code: http.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: "USDA API error: HTTP \(http.statusCode)"])
        }
    }
}

// MARK: - Request/Response models

private struct FoodSearchRequest: Codable {
    let query: String
    let dataType: [String]
    let pageSize: Int
    let pageNumber: Int
}

private struct FoodSearchResponse: Codable {
    let foods: [FoodSearchFood]?
}

private struct FoodSearchFood: Codable {
    let fdcId: Int
    let description: String
    let dataType: String
}

private struct FoodDetailsResponse: Codable {
    let foodNutrients: [FoodNutrient]?
}

private struct FoodNutrient: Codable {
    let nutrient: NutrientInfo?
    let foodNutrientId: Int?
    let amount: Double?
}

private struct NutrientInfo: Codable {
    let id: Int?
}

// MARK: - URL helper

private extension URL {
    func appending(queryItems: [URLQueryItem]) -> URL {
        var comps = URLComponents(url: self, resolvingAgainstBaseURL: false)!
        var existing = comps.queryItems ?? []
        existing.append(contentsOf: queryItems)
        comps.queryItems = existing
        return comps.url!
    }
}
