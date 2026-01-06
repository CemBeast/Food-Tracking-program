//
//  FoodModel.swift
//  FoodTrackingApp
//
//  Created by Cem Beyenal on 5/8/25.
//

import Foundation

class FoodModel: ObservableObject {
    @Published var items: [FoodItem] = []
    
    init() {
        load()
    }
    
    func add(_ item: FoodItem) {
        if item.isMeal {
            if let idx = items.firstIndex(where: { $0.id == item.id }) {
                items[idx] = item
            } else {
                items.append(item)
            }
            print("💾 FoodModel saved meal:", item.name, "id:", item.id, "ingredients:", item.ingredients.count)
            save()
            return
        }
        
        // non-meal: prevent duplicates by name
        if items.contains(where: { !$0.isMeal && $0.name.lowercased() == item.name.lowercased() }) {
            return
        }
        print("💾 FoodModel.add() called for:", item.name)
        items.append(item)
        save()
    }
    
    func save() {
        saveFoodItems(items)
    }
    
    func load() {
        print("🛠 Documents Directory:", getDocumentsDirectory().path)
        items = loadFoodItems()
    }
    
    // For Testing purposes to clear the dictionary
    func clearUserFoodDictionary() {
        items = []
        save() // This will overwrite the file with an empty array []
        print("🧹 Cleared user food dictionary.")
    }
}
