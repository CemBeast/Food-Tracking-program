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

func loadFoodItems() -> [FoodItem] {
    let url = getDocumentsDirectory().appendingPathComponent(foodDictionaryFileName)
    guard FileManager.default.fileExists(atPath: url.path) else {
        return [] // Starts with empty if file doesn't exist
    }
    
    do {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([FoodItem].self, from: data)
    } catch {
        print ("Failed to load food items: \(error)")
        return []
    }
}
