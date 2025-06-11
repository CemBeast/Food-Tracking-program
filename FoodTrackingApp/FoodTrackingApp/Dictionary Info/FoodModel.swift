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
        // never add the same food name twice
        guard !items.contains(where: { $0.name.lowercased() == item.name.lowercased() }) else {
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
