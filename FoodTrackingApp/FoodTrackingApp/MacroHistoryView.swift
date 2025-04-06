//
//  MacroHistoryView.swift
//  FoodTrackingApp
//
//  Created by Cem Beyenal on 12/25/24.
//


import SwiftUI

struct MacroHistoryView: View {
    @ObservedObject var viewModel: MacroTrackerViewModel
    @State private var selectedDate: String? = nil
    @State private var selectedFoodEntries: [FoodEntry] = []

    
    struct MacroHistory: Identifiable {
            let id = UUID()
            let date: String
            let calories: Int
            let protein: Double
            let carbs: Double
            let fats: Double
            let foodEntries:  [FoodEntry] // Ensure this property exists!
        }
    
    var body: some View {
        List {
            ForEach(viewModel.getAllMacroHistory(), id: \.date) { history in
                NavigationLink(
                    destination: MacroDetailView(
                        date: history.date,
                        foodEntries: history.foodEntries
                    )
                ) {
                    VStack(alignment: .leading) {
                        Text("Date: \(history.date)")
                            .font(.headline)
                        Text("Calories: \(history.calories)")
                    }
                }
                .onTapGesture{
                    print("Navigating to MacroDetailView with \(history.foodEntries.count) food entries")
                }
            }
        }
        .navigationTitle("Macro History")
    }
}
