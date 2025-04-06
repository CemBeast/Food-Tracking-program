//
//  MacroTrackerViewModel.swift
//  FoodTrackingApp
//
//  Created by Cem Beyenal on 12/25/24.
//


import Foundation

struct FoodEntry: Identifiable {
    let id = UUID()
    let name: String
    let calories: Int
    let protein: Double
    let carbs: Double
    let fats: Double
    let servings: Int
}

class MacroTrackerViewModel: ObservableObject {
    @Published var calories = 0
    @Published var protein = 0.0
    @Published var carbs = 0.0
    @Published var fats = 0.0
    @Published var foodEntries: [FoodEntry] = []
    
    private let userDefaultsKey = "dailyMacros"
    private let lastSavedDateKey = "lastSavedDate"

    struct MacroHistory: Identifiable {
            let id = UUID()
            let date: String
            let calories: Int
            let protein: Double
            let carbs: Double
            let fats: Double
            let foodEntries: [FoodEntry]
        }
    
    init() {
        checkAndResetForNewDay()
    }

    func saveMacros(for date: String) {
        print("🔹 Saving macros for \(date) with \(foodEntries.count) food entries.")
        
        let foodEntriesData = foodEntries.map { entry in
            [
                "name": entry.name,
                "calories": entry.calories,
                "protein": entry.protein,
                "carbs": entry.carbs,
                "fats": entry.fats,
                "servings": entry.servings
            ] as [String: Any]
        }
        
        let macros: [String: Any] = [
            "calories": calories,
            "protein": protein,
            "carbs": carbs,
            "fats": fats,
            "foodEntries": foodEntriesData // Properly saving as an array
        ]
        
        var savedData = UserDefaults.standard.dictionary(forKey: userDefaultsKey) as? [String: [String: Any]] ?? [:]
        savedData[date] = macros
        UserDefaults.standard.set(savedData, forKey: userDefaultsKey)
        print("✅ Macros saved for \(date): \(macros)")
    }

    func loadMacros(for date: String) {
        let savedData = UserDefaults.standard.dictionary(forKey: userDefaultsKey) as? [String: [String: Any]] ?? [:]
        if let macros = savedData[date] {
            print("🔹 Loading macros for \(date): \(macros)")

            self.calories = macros["calories"] as? Int ?? 0
            self.protein = macros["protein"] as? Double ?? 0.0
            self.carbs = macros["carbs"] as? Double ?? 0.0
            self.fats = macros["fats"] as? Double ?? 0.0
            // Load food entries
            self.foodEntries = (macros["foodEntries"] as? [[String: Any]] ?? []).compactMap { entry in
                        guard
                    let name = entry["name"] as? String,
                    let calories = entry["calories"] as? Int,
                    let protein = entry["protein"] as? Double,
                    let carbs = entry["carbs"] as? Double,
                    let fats = entry["fats"] as? Double,
                    let servings = entry["servings"] as? Int
                else { return nil }
                
                return FoodEntry(
                    name: name,
                    calories: calories,
                    protein: protein,
                    carbs: carbs,
                    fats: fats,
                    servings: servings
                )
            }
            print("Loaded food entries for \(date): \(self.foodEntries.count) items")
        } else {
            print("❌ No macros found for \(date)")
                   resetMacros()
            resetMacros()
        }
    }

    func resetMacros() {
        calories = 0
        protein = 0.0
        carbs = 0.0
        fats = 0.0
    }

    func checkAndResetForNewDay() {
        let today = formatDate(Date())
        let lastSavedDate = UserDefaults.standard.string(forKey: lastSavedDateKey) ?? ""

        if lastSavedDate != today {
            if !lastSavedDate.isEmpty {
                saveMacros(for: lastSavedDate)
            }
            resetMacros()
            UserDefaults.standard.set(today, forKey: lastSavedDateKey)
        } else {
            loadMacros(for: today)
        }
    }

    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    /// Gets History of all Macros 
    func getAllMacroHistory() -> [MacroHistory] {
        let savedData = UserDefaults.standard.dictionary(forKey: userDefaultsKey) as? [String: [String: Any]] ?? [:]

        let historyList: [MacroHistory] = savedData.compactMap { (date, macros) in
            guard let calories = macros["calories"] as? Int,
                  let protein = macros["protein"] as? Double,
                  let carbs = macros["carbs"] as? Double,
                  let fats = macros["fats"] as? Double,
                  let foodEntriesRaw = macros["foodEntries"] as? [[String: Any]] else {
                return nil
            }

            let foodEntries: [FoodEntry] = foodEntriesRaw.compactMap { entry in
                guard let name = entry["name"] as? String,
                      let calories = entry["calories"] as? Int,
                      let protein = entry["protein"] as? Double,
                      let carbs = entry["carbs"] as? Double,
                      let fats = entry["fats"] as? Double,
                      let servings = entry["servings"] as? Int else {
                    return nil
                }

                return FoodEntry(
                    name: name,
                    calories: calories,
                    protein: protein,
                    carbs: carbs,
                    fats: fats,
                    servings: servings
                )
            }

            return MacroHistory(
                date: date,
                calories: calories,
                protein: protein,
                carbs: carbs,
                fats: fats,
                foodEntries: foodEntries
            )
        }

        // Convert date string to Date type and sort
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        return historyList.sorted {
            guard let date1 = dateFormatter.date(from: $0.date),
                  let date2 = dateFormatter.date(from: $1.date) else {
                return false
            }
            return date1 > date2
        }
    }
}
