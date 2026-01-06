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
    let id: UUID
    let date: Date
    let calories: Int
    let protein: Double
    let carbs: Double
    let fats: Double
    let foodsEaten: [LoggedFoodEntry] // Stores food ate within that day
    
    init(
        id: UUID = UUID(),
        date: Date,
        calories: Int,
        protein: Double,
        carbs: Double,
        fats: Double,
        foodsEaten: [LoggedFoodEntry]
    ) {
        self.id = id
        self.date = date
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fats = fats
        self.foodsEaten = foodsEaten
    }
    
    enum CodingKeys: String, CodingKey {
        case id, date, calories, protein, carbs, fats, foodsEaten
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        date = try c.decode(Date.self, forKey: .date)
        calories = try c.decode(Int.self, forKey: .calories)
        protein = try c.decode(Double.self, forKey: .protein)
        carbs = try c.decode(Double.self, forKey: .carbs)
        fats = try c.decode(Double.self, forKey: .fats)
        foodsEaten = try c.decode([LoggedFoodEntry].self, forKey: .foodsEaten)
    }
}

// Struct to represent a logged food (since foodItem does not have weight/ servings)
struct LoggedFoodEntry: Identifiable, Codable {
    let id: UUID
    var food: FoodItem
    var quantity: Double
    var mode: MeasurementMode
    var servingUnit: ServingUnit
    var timestamp: Date

    init(food: FoodItem, quantity: Double, mode: MeasurementMode, servingUnit: ServingUnit, timestamp: Date) {
        self.id = UUID()
        self.food = food
        self.quantity = quantity
        self.mode = mode
        self.servingUnit = servingUnit
        self.timestamp = timestamp
    }
    
    // Computed ratio based on measurement mode
    var scalingFactor: Double {
        switch mode {
        case .weight:
            // If weightInGrams is zero, just treat it as zero rather than inf/NaN:
            guard food.weightInGrams > 0 else { return 0.0 }
            return Double(quantity) / Double(food.weightInGrams)
        case .serving:
            // If “servings” (number of grams per serving) is zero, avoid dividing by zero:
            guard food.servings > 0 else { return 0.0 }
            return Double(quantity) / Double(food.servings)
        }
    }

    // Computed macros
    var scaledCalories: Int {
        Int(Double(food.calories) * scalingFactor)
    }

    var scaledProtein: Double {
        food.protein * scalingFactor
    }

    var scaledCarbs: Double {
        food.carbs * scalingFactor
    }

    var scaledFats: Double {
        food.fats * scalingFactor
    }
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
    
    // Temp values
    @Published var caloriesGoal: Int = 0
    @Published var proteinGoal: Double = 0
    @Published var carbGoal: Double = 0
    @Published var fatGoal: Double = 0
    
    // UserDefaults Key to store the encoded history
    private let historyKey = "macro_history"
    private let lastDateKey = "macro_last_updated"
    private let caloriesKey   = "macro_calories"
    private let proteinKey    = "macro_protein"
    private let carbsKey      = "macro_carbs"
    private let fatsKey       = "macro_fats"
    private let caloriesGoalKey = "macro_calorie_goal"
    private let proteinGoalKey = "macro_protein_goal"
    private let carbsGoalKey    = "macro_carbs_goal"
    private let fatsGoalKey     = "macro_fats_goal"
    private let foodLogKey = "macro_food_log"
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        let defaults = UserDefaults.standard
        
        // Load persisted Macros
        self.calories = defaults.integer(forKey: caloriesKey)
        self.protein = defaults.double(forKey: proteinKey)
        self.carbs = defaults.double(forKey: carbsKey)
        self.fats = defaults.double(forKey: fatsKey)
        // Load persisted Goal Macros
        self.caloriesGoal = defaults.integer(forKey: caloriesGoalKey)
        self.proteinGoal = defaults.double(forKey: proteinGoalKey)
        self.carbGoal = defaults.double(forKey: carbsGoalKey)
        self.fatGoal = defaults.double(forKey: fatsGoalKey)
        
        loadHistory()
        loadLastDate()
        loadFoodLog()
        
        // Persist Dailymacros/foodLog/macrogoals whenever they change
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
        $foodLog
            .sink {_ in self.saveFoodLog()}
            .store(in: &cancellables)
        $caloriesGoal
            .sink { val in defaults.set(val, forKey: self.caloriesGoalKey) }
            .store(in: &cancellables)
        $proteinGoal
            .sink { val in defaults.set(val, forKey: self.proteinGoalKey) }
            .store(in: &cancellables)
        $carbGoal
            .sink { val in defaults.set(val, forKey: self.carbsGoalKey) }
            .store(in: &cancellables)
        $fatGoal
            .sink { val in defaults.set(val, forKey: self.fatsGoalKey) }
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
        // save yesterdays macros and foodLog 
        let entry = MacroHistoryEntry(date: lastUpdatedDate, calories: calories, protein: protein, carbs: carbs, fats: fats, foodsEaten: foodLog)
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
        foodLog = []
        UserDefaults.standard.removeObject(forKey: foodLogKey)
    }
    
    // Function to increase macros from logging and put it in food log to track what was ate
    func logFood(_ item: FoodItem, gramsOrServings: Double, mode: MeasurementMode, at time: Date = Date()) {
        print("🍽 Logging food: \(item.name), qty: \(gramsOrServings), mode: \(mode)")
        let factor: Double = {
            switch mode {
            case .weight:
                guard item.weightInGrams > 0 else { return 0.0 }
                return gramsOrServings / Double(item.weightInGrams)
            case .serving:
                // If servings‐per‐item is zero, avoid dividing by zero:
                guard item.servings > 0 else { return 0.0 }
                return gramsOrServings / Double(item.servings)
            }
        }()
        
        // increment daily macros
        calories += Int(Double(item.calories) * factor)
        protein += item.protein * factor
        carbs += item.carbs * factor
        fats += item.fats * factor
        
        let entry = LoggedFoodEntry(food: item, quantity: gramsOrServings, mode: mode, servingUnit: item.servingUnit, timestamp: time)
        foodLog = foodLog + [entry] // triggers Combine
        saveFoodLog()
    }
    
    // Save the food log persistantly
    private func saveFoodLog() {
        if let encoded = try? JSONEncoder().encode(foodLog) {
            UserDefaults.standard.set(encoded, forKey: foodLogKey)
            print("✅ Food log saved: \(foodLog.count) entries")
        } else {
            print("❌ Failed to encode foodLog")
        }
    }
    
    // load the saved data
    private func loadFoodLog() {
        if let data = UserDefaults.standard.data(forKey: foodLogKey),
           let decoded = try? JSONDecoder().decode([LoggedFoodEntry].self, from: data) {
            foodLog = decoded
            print("✅ Loaded foodLog with \(foodLog.count) items")
        } else {
            print("❌ No food log found or decoding failed")
        }
    }
    
    // Delete a food from the log
    func deleteFoodLogEntry(_ entry: LoggedFoodEntry) {
        let factor: Double = {
            switch entry.mode {
            case .weight:
                return Double(entry.quantity) / Double(entry.food.weightInGrams)
            case .serving:
                return Double(entry.quantity) / Double(entry.food.servings)
            }
        }()
        
        // Subtract macros
        calories -= Int(Double(entry.food.calories) * factor)
        protein  -= entry.food.protein * factor
        carbs    -= entry.food.carbs * factor
        fats     -= entry.food.fats * factor
        
        // Safeguard against negative totals
        calories = max(0, calories)
        protein  = max(0, protein)
        carbs    = max(0, carbs)
        fats     = max(0, fats)
        
        // Remove entry and save Food log
        foodLog.removeAll { $0.id == entry.id }
        saveFoodLog()
    }
    
    func updateFoodEntryQuantity(_ entry: LoggedFoodEntry, newQuantity: Double) {
        guard let index = foodLog.firstIndex(where: { $0.id == entry.id }) else { return }
        
        let oldFactor = computeFactor(entry.quantity, entry.food, entry.mode)
        let newFactor = computeFactor(newQuantity, entry.food, entry.mode)
        
        calories += Int(Double(entry.food.calories) * (newFactor - oldFactor))
        protein  += entry.food.protein * (newFactor - oldFactor)
        carbs    += entry.food.carbs * (newFactor - oldFactor)
        fats     += entry.food.fats * (newFactor - oldFactor)
        
        var updatedEntry = foodLog[index]
        updatedEntry.quantity = newQuantity
        foodLog[index] = updatedEntry
        saveFoodLog()
    }
    
    private func computeFactor(_ quantity: Double, _ food: FoodItem, _ mode: MeasurementMode) -> Double {
        switch mode {
            case .weight:
                guard food.weightInGrams > 0 else { return 0.0 }
                return quantity / Double(food.weightInGrams)
            case .serving:
                guard food.servings > 0 else { return 0.0 }
            return quantity / Double(food.servings)
        }
    }
    
    // For saving macros to be seen on widget
    func saveDailyMacrosToDefaults() {
        let defaults = UserDefaults(suiteName: "group.com.yourname.FoodTrackingApp")
        defaults?.set(calories, forKey: "calories")
        defaults?.set(protein, forKey: "protein")
        defaults?.set(carbs, forKey: "carbs")
        defaults?.set(fats, forKey: "fats")
    }
}
