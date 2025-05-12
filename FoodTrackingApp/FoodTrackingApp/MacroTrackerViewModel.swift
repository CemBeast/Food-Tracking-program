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

class MacroTrackerViewModel: ObservableObject {
    @Published var calories = 0
    @Published var protein = 0.0
    @Published var carbs = 0.0
    @Published var fats = 0.0
    
    // Historical macro entries, lastUpdatedDate is used for updating history when its a new day
    @Published var history: [MacroHistoryEntry] = []
    @Published var lastUpdatedDate: Date = Date()
    
    // UserDefaults Key to store the encoded history
    private let historyKey = "macro_history"
    private let lastDateKey = "macro_last_updated"
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadHistory()
        loadLastDate()
        checkForNewDay()
        
        // Run check when app becomes active again
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.checkForNewDay()
            }
            .store(in: &cancellables)
    }
    
    func resetForNewdDay() {
        let entry = MacroHistoryEntry(date: Date(), calories: calories, protein: protein, carbs: carbs, fats: fats)
        history.append(entry)
        saveHistory()
        
        // reset macros
        calories = 0
        protein = 0.0
        carbs = 0.0
        fats = 0.0
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
        }
       
    private func rollOverToNewDay() {
        // save yesterdays macros
        let entry = MacroHistoryEntry(date: lastUpdatedDate, calories: calories, protein: protein, carbs: carbs, fats: fats)
        history.append(entry)
            saveHistory()

        // Reset current macros
        calories = 0
        protein = 0.0
        carbs = 0.0
        fats = 0.0

        // Update date
        lastUpdatedDate = Date()
        saveLastDate()
    }
    
    private func saveLastDate() {
        UserDefaults.standard.set(lastUpdatedDate, forKey: lastDateKey)
    }

    private func loadLastDate() {
        if let savedDate = UserDefaults.standard.object(forKey: lastDateKey) as? Date {
            lastUpdatedDate = savedDate
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
    }
}
