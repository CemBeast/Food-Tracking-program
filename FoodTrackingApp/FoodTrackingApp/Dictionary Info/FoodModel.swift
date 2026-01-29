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
        mergeBundledDefaultsIfNeeded()
    }
    
    // For Testing purposes to clear the dictionary
    func clearUserFoodDictionary() {
        items = []
        save() // This will overwrite the file with an empty array []
        print("🧹 Cleared user food dictionary.")
    }

    /// Merge newer bundled defaults into the user's dictionary without overwriting user edits.
    /// - Only adds missing items.
    /// - Matches by `id` first, then by case-insensitive name for non-meals.
    private func mergeBundledDefaultsIfNeeded() {
        let lastMerged = UserDefaults.standard.integer(forKey: defaultsMergedVersionKey)
        guard lastMerged < bundledDefaultsVersion else { return }

        let bundled = loadDefaultFoodItems(from: bundledDefaultsFileName)
        let didChange = mergeDefaultsAddMissing(bundled)
        if didChange {
            save()
        }
        UserDefaults.standard.set(bundledDefaultsVersion, forKey: defaultsMergedVersionKey)
        print("✅ Merged bundled defaults v\(bundledDefaultsVersion) (was v\(lastMerged))")
    }

    private func mergeDefaultsAddMissing(_ defaults: [FoodItem]) -> Bool {
        guard !defaults.isEmpty else { return false }

        let existingIDs = Set(items.map { $0.id })
        let existingNonMealNames = Set(items.filter { !$0.isMeal }.map { $0.name.lowercased() })

        var didChange = false
        for item in defaults {
            if existingIDs.contains(item.id) { continue }
            if !item.isMeal && existingNonMealNames.contains(item.name.lowercased()) { continue }
            items.append(item)
            didChange = true
        }
        return didChange
    }

    /// Optional remote defaults merge hook (does not overwrite user edits).
    @MainActor
    func mergeDefaultsFromRemote(url: URL) async throws {
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoded = try JSONDecoder().decode([FoodItem].self, from: data)
        if mergeDefaultsAddMissing(decoded) {
            save()
        }
    }
}
