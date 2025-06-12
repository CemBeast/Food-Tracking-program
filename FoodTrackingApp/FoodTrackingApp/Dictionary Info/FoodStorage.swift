//
//  FoodStorage.swift
//  FoodTrackingApp
//
//  Created by Cem Beyenal on 5/8/25.
//

import Foundation

let foodDictionaryFileName = "user_foods.json"

func getDocumentsDirectory() -> URL {
    FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
}

func saveFoodItems(_ items : [FoodItem]) {
    let url = getDocumentsDirectory().appendingPathComponent(foodDictionaryFileName)
    do {
        let data = try JSONEncoder().encode(items)
        try data.write(to: url)
    } catch {
        print("Failed to save food items: \(error)")
    }
}

// Need to make it load the selected food dictionary when user is prompted upon first launch
func loadFoodItems() -> [FoodItem] {
    let url = getDocumentsDirectory().appendingPathComponent(foodDictionaryFileName)
    print("📂 Loading from user_foods.json at: \(url.path)")

    if FileManager.default.fileExists(atPath: url.path) {
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([FoodItem].self, from: data)
            
            if decoded.isEmpty {
                print("📭 user_foods.json is empty. Loading empty.")
//                let defaultItems = loadDefaultFoodItems(from: "default_all")
//                saveFoodItems(defaultItems)
                return []
            }

            return decoded
        } catch {
            print("❌ Failed to load user food items: \(error)")
            return []
        }
    } else {
        print("📭 user_foods.json does not exist. Loading default.")
        let defaultItems = loadDefaultFoodItems(from: "default_all")
        saveFoodItems(defaultItems)
        return defaultItems
    }
}

func loadDefaultFoodItems(from fileName: String) -> [FoodItem] {
    guard let url = Bundle.main.url(forResource: fileName, withExtension: "json") else {
        print("❌ Default food file not found.")
        return []
    }

    do {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([FoodItem].self, from: data)
    } catch {
        print("❌ Failed to load default foods: \(error)")
        return []
    }
}
