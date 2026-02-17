//
//  USDANutritionService.swift
//  FoodTrackingApp
//
//  Survey-only USDA FoodData Central lookup
//

import Foundation

// MARK: - Public types

enum USDASearchScope {
    case foundation     // Foundation
    case branded     // Branded
    case survey     // Survey (FNDDS)
}

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

    // MARK: - Public API

    /// Parameters: given a raw query and the scope of the searcy, the function normalizes the query and decides which category to search from (survery or brands)
    /// Function then calls searchBestMatch (which returns one USDA food choice)
    /// Then calls fetchMacrosForFood to return the normalized string, the best USDAFoodChoice and that foods macros per 100g
    func fetchSurveyMacrosPer100g(query rawQuery: String, scope: USDASearchScope = .survey) async throws -> (queryNormalized: String, choice: USDAFoodChoice, macros: MacrosPer100g) {
        guard !apiKey.isEmpty else {
            throw NSError(domain: "USDANutritionService", code: 900,
                          userInfo: [NSLocalizedDescriptionKey: "Missing FDC_API_KEY (check Secrets.xcconfig + Info.plist)."])
        }

        // clean query and select scope
        let queryNormalized = normalizeQuery(rawQuery)
        let dataTypes: [String]
            switch scope {
            case .foundation:
                dataTypes = ["Foundation"]
            case .survey:
                dataTypes = ["Survey (FNDDS)"]
            case .branded:
                dataTypes = ["Branded"]
        }


        if let choice = try await searchBestMatch(query: queryNormalized, dataTypes: dataTypes) {
            let macros = try await fetchMacrosForFood(fdcId: choice.fdcId)
            return (queryNormalized, choice, macros)
        }
        
        let scopeName: String
        switch scope {
            case .survey:
                scopeName = "Survey (FNDDS)"
            case .foundation:
                scopeName = "Foundation"
            case .branded:
                scopeName = "Branded"
        }
        
        throw NSError(domain: "USDANutritionService", code: 404,
                      userInfo: [NSLocalizedDescriptionKey: "No \(scopeName) results found for: \(queryNormalized)"])
    }
    
    /// Same as fetchSurveryMacros100g but returns an array instead
    /// Takes raw query and scope to call searchTopMatches to return the top 5
    /// Public func to Return top N choices in USDA FoodChoice (no macros ). Uses the same scoring.
    func searchTopChoices(
        query rawQuery: String,
        scope: USDASearchScope = .survey,
        limit: Int = 5
    ) async throws -> (queryNormalized: String, choices: [USDAFoodChoice]) {

        guard !apiKey.isEmpty else {
            throw NSError(domain: "USDANutritionService", code: 900,
                          userInfo: [NSLocalizedDescriptionKey: "Missing FDC_API_KEY (check Secrets.xcconfig + Info.plist)."])
        }

        let queryNormalized = normalizeQuery(rawQuery)

        let dataTypes: [String]
        switch scope {
        case .survey: dataTypes = ["Survey (FNDDS)"]
        case .branded: dataTypes = ["Branded"]
        case .foundation: dataTypes = ["Foundation"]
        }

        // 1) Try primary dataTypes
        if let choices = try await searchTopMatches(query: queryNormalized, dataTypes: dataTypes, limit: limit),
           !choices.isEmpty {
            return (queryNormalized, choices)
        }

        let scopeName: String
        switch scope {
            case .survey:
                scopeName = "Survey (FNDDS)"
            case .foundation:
                scopeName = "Foundation"
            case .branded:
                scopeName = "Branded"
        }
        
        throw NSError(domain: "USDANutritionService", code: 404,
                      userInfo: [NSLocalizedDescriptionKey: "No \(scopeName) results found for: \(queryNormalized)"])
    }
    
    // public function to access the food macros for an already retrieved food
    // fetches exact macros of a food (used for selecting macros from a list)
    func fetchMacrosPer100gForFood(fdcId: Int) async throws -> MacrosPer100g {
        try await fetchMacrosForFood(fdcId: fdcId)
    }

    // MARK: - Search (helper functions for Public API functions)
    /// Searches using api for the cleaned query to return the single best food based on score function
    /// Is called from fetchMacrosPer100g
    /// Returns  a USDAFoodChoice
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

        // return the first result from USDA
        guard let firstFood = foods.first else { return nil }
        return USDAFoodChoice(
            fdcId: firstFood.fdcId,
            description: firstFood.description,
            dataType: firstFood.dataType
        )
       
    }
    
    
    // Same as above excetpt it returns a list
    private func searchTopMatches(
        query: String,
        dataTypes: [String],
        limit: Int
    ) async throws -> [USDAFoodChoice]? {

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
        
        // Tjust take first N foods
        let top = foods.prefix(max(1, limit))

        return top.map {
            USDAFoodChoice(
                fdcId: $0.fdcId,
                description: $0.description,
                dataType: $0.dataType
            )
        }

        
    }

    // MARK: - Details (nutrients)
    /// Given the USDA fdcID, this function fetches the maros for the food
    /// returns macros per 100g
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
