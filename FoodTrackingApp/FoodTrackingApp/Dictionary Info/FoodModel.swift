//
//  FoodModel.swift
//  FoodTrackingApp
//
//  Created by Cem Beyenal on 5/8/25.
//

import Foundation

class FoodModel: ObservableObject {
    @Published var items: [FoodItem] = []

    lazy var bundledDefaultIDs: Set<UUID> = Set(
        loadDefaultFoodItems(from: bundledDefaultsFileName).map { $0.id }
    )

    init() {
        load()
    }

    func isUserAdded(_ item: FoodItem) -> Bool {
        !bundledDefaultIDs.contains(item.id)
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

    /// Reseed the dictionary from bundled defaults when the bundled version advances.
    /// v2 wipes the entire user dictionary (including meals) and replaces it with the bundled set.
    /// Earlier versions only added missing items.
    private func mergeBundledDefaultsIfNeeded() {
        let lastMerged = UserDefaults.standard.integer(forKey: defaultsMergedVersionKey)
        guard lastMerged < bundledDefaultsVersion else { return }

        let bundled = loadDefaultFoodItems(from: bundledDefaultsFileName)
        guard !bundled.isEmpty else {
            print("⚠️ Bundled defaults empty, skipping reseed (was v\(lastMerged))")
            return
        }

        items = bundled
        save()
        bundledDefaultIDs = Set(bundled.map { $0.id })
        UserDefaults.standard.set(bundledDefaultsVersion, forKey: defaultsMergedVersionKey)
        print("♻️ Wiped and reseeded bundled defaults v\(bundledDefaultsVersion) (was v\(lastMerged)) — \(bundled.count) items")
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
