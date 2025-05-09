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
        items.append(item)
        save()
    }
    
    func save() {
        saveFoodItems(items)
    }
    
    func load() {
        items = loadFoodItems()
    }
}
