//
//  MacroTrackerViewModel.swift
//  FoodTrackingApp
//
//  Created by Cem Beyenal on 12/25/24.
//
import Foundation
import SwiftUI
import Combine

// Struct to represent a day's macro data
struct MacroHistoryEntry: Identifiable, Codable {
    let id = UUID()
    let date: Date
    let calories: Int
    let protein: Double
    let carbs: Double
    let fats: Double
}

// Struct to represent a logged food (since foodItem does not have weight/ servings)
struct LoggedFoodEntry: Identifiable {
    let id = UUID()
    var food: FoodItem
    var quantity: Int
    var mode: MeasurementMode
    var servingUnit: ServingUnit
}

class MacroTrackerViewModel: ObservableObject {
    @Published var calories = 0
    @Published var protein = 0.0
    @Published var carbs = 0.0
    @Published var fats = 0.0
    // Historical macro entries, lastUpdatedDate is used for updating history when its a new day
    @Published var history: [MacroHistoryEntry] = []
    @Published var lastUpdatedDate: Date = Date()
    @Published var foodLog: [LoggedFoodEntry] = [] // Tracks food for the day
    
    // UserDefaults Key to store the encoded history
    private let historyKey = "macro_history"
    private let lastDateKey = "macro_last_updated"
    private let caloriesKey   = "macro_calories"
    private let proteinKey    = "macro_protein"
    private let carbsKey      = "macro_carbs"
    private let fatsKey       = "macro_fats"
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        let defaults = UserDefaults.standard
        
        // Load persisted Macros
        self.calories = defaults.integer(forKey: caloriesKey)
        self.protein = defaults.double(forKey: proteinKey)
        self.carbs = defaults.double(forKey: carbsKey)
        self.fats = defaults.double(forKey: fatsKey)
        
        loadHistory()
        loadLastDate()
        
        // Persist macros whenever they change
        $calories
            .sink { val in defaults.set(val, forKey: self.caloriesKey) }
            .store(in: &cancellables)
        $protein
            .sink { val in defaults.set(val, forKey: self.proteinKey) }
            .store(in: &cancellables)
        $carbs
            .sink { val in defaults.set(val, forKey: self.carbsKey) }
            .store(in: &cancellables)
        $fats
            .sink { val in defaults.set(val, forKey: self.fatsKey) }
            .store(in: &cancellables)
        
        checkForNewDay()
        
        // Run check when app becomes active again
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in self?.checkForNewDay() }
            .store(in: &cancellables)
    }

    // Save the 'history' array to UserDefaults by encoding it to JSON
    private func saveHistory() {
        // Try to convert '[MacroHistoryEntry]' into 'Data'
        if let encoded = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(encoded, forKey: historyKey)
        }
    }

    private func loadHistory() {
        // Try to read saved Data from UserDefaults
        if let data = UserDefaults.standard.data(forKey: historyKey),
           let decoded = try? JSONDecoder().decode([MacroHistoryEntry].self, from: data){
            history = decoded
        }
        else {
            self.history = []
        }
    }
       
    private func rollOverToNewDay() {
        // save yesterdays macros
        let entry = MacroHistoryEntry(date: lastUpdatedDate, calories: calories, protein: protein, carbs: carbs, fats: fats)
        history.append(entry)
            saveHistory()

        // Reset current macros
        resetMacros()

        // Update date
        lastUpdatedDate = Date()
        saveLastDate()
    }
    
    private func saveLastDate() {
        UserDefaults.standard.set(lastUpdatedDate, forKey: lastDateKey)
    }

    private func loadLastDate() {
        if let savedDate = UserDefaults.standard.object(forKey: lastDateKey) as? Date {
            self.lastUpdatedDate = Calendar.current.startOfDay(for: savedDate)
        } else {
            self.lastUpdatedDate = Calendar.current.startOfDay(for: Date())
            saveLastDate()
        }
    }
    
    private func checkForNewDay() {
        if !Calendar.current.isDateInToday(lastUpdatedDate) {
            rollOverToNewDay()
        }
    }
    
    func clearHistory() {
        history.removeAll() // Clear macro history array
        UserDefaults.standard.removeObject(forKey: historyKey)
        lastUpdatedDate = Calendar.current.startOfDay(for: Date())
        saveLastDate()
    }
    
    func resetMacros() {
        calories = 0
        protein  = 0
        carbs    = 0
        fats     = 0
        // (the Combine sinks you already have will write zeros back to UserDefaults)
    }
    
    // Function to increase macros from logging and put it in food log to track what was ate
    func logFood(_ item: FoodItem, gramsOrServings: Int, mode: MeasurementMode) {
        let factor: Double = {
            switch mode {
            case .weight:
                return Double(gramsOrServings) / Double(item.weightInGrams)
            case .serving:
                return Double(gramsOrServings)
            }
        }()
        
        calories += Int(Double(item.calories) * factor)
        protein += item.protein * factor
        carbs += item.carbs * factor
        fats += item.fats * factor
        
        // Log actual portion consumed
//        let consumed = FoodItem(
//            name: item.name,
//            weightInGrams: mode == .weight ? gramsOrServings : item.weightInGrams,
//            servings: mode == .serving ? gramsOrServings : 1,
//            calories: Int(Double(item.calories) * factor),
//            protein: item.protein * factor,
//            carbs: item.carbs * factor,
//            fats: item.fats * factor,
//            servingUnit: item.servingUnit
//        )
//        
//        // Add food to food log
//        foodLog.append(consumed)
        let entry = LoggedFoodEntry(food: item, quantity: gramsOrServings, mode: mode, servingUnit: item.servingUnit)
         foodLog.append(entry)
        
    }
}
