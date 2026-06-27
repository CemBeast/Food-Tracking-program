//
//  FoodStorage.swift
//  FoodTrackingApp
//
//  Created by Cem Beyenal on 5/8/25.
//

import Foundation

let foodDictionaryFileName = "user_foods.json"
let bundledDefaultsFileName = "default_all"
let bundledDefaultsVersion = 4
let defaultsMergedVersionKey = "defaults_merged_version"

func getDocumentsDirectory() -> URL {
    if let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
        return url
    }
    // Should never happen on iOS, but fall back to a temp dir instead of crashing.
    return URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
}

func saveFoodItems(_ items : [FoodItem]) {
    let url = getDocumentsDirectory().appendingPathComponent(foodDictionaryFileName)
    do {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(items)
        try data.write(to: url, options: [.atomic])
        
        if let meal = items.first(where: { $0.isMeal }) {
            debugLog("💾 SAVING MEAL:", meal.name, "id:", meal.id, "ingredients:", meal.ingredients.count)
        }
    } catch {
        debugLog("Failed to save food items: \(error)")
    }
}

// Need to make it load the selected food dictionary when user is prompted upon first launch
func loadFoodItems() -> [FoodItem] {
    let url = getDocumentsDirectory().appendingPathComponent(foodDictionaryFileName)
    debugLog("📂 Loading from user_foods.json at: \(url.path)")

    if FileManager.default.fileExists(atPath: url.path) {
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([FoodItem].self, from: data)
            if let meal = decoded.first(where: { $0.isMeal }) {
                debugLog("📦 LOADED MEAL:", meal.name, "id:", meal.id, "ingredients:", meal.ingredients.count)
            }
            
            if decoded.isEmpty {
                let lastMerged = UserDefaults.standard.integer(forKey: defaultsMergedVersionKey)
                if lastMerged < bundledDefaultsVersion {
                    debugLog("📭 user_foods.json is empty. Seeding bundled defaults v\(bundledDefaultsVersion).")
                    let defaultItems = loadDefaultFoodItems(from: bundledDefaultsFileName)
                    saveFoodItems(defaultItems)
                    UserDefaults.standard.set(bundledDefaultsVersion, forKey: defaultsMergedVersionKey)
                    return defaultItems
                } else {
                    debugLog("📭 user_foods.json is empty. Keeping empty (defaults already merged v\(lastMerged)).")
                    return []
                }
            }

            return decoded
        } catch {
            debugLog("❌ Failed to load user food items: \(error)")
            return []
        }
    } else {
        debugLog("📭 user_foods.json does not exist. Loading default.")
        let defaultItems = loadDefaultFoodItems(from: bundledDefaultsFileName)
        saveFoodItems(defaultItems)
        UserDefaults.standard.set(bundledDefaultsVersion, forKey: defaultsMergedVersionKey)
        return defaultItems
    }
}

func loadDefaultFoodItems(from fileName: String) -> [FoodItem] {
    guard let url = Bundle.main.url(forResource: fileName, withExtension: "json") else {
        debugLog("❌ Default food file not found.")
        return []
    }

    do {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([FoodItem].self, from: data)
    } catch {
        debugLog("❌ Failed to load default foods: \(error)")
        return []
    }
}
