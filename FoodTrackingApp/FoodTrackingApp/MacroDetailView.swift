//
//  MacroDetailView.swift
//  FoodTrackingApp
//
//  Created by Cem Beyenal on 12/25/24.
//

import SwiftUI

struct MacroDetailView: View {
    let date: String
    let foodEntries: [FoodEntry]
    
    var body: some View {
        VStack {
            Text("Details for \(date)")
                .font(.largeTitle)
                .padding()
            
            if foodEntries.isEmpty {
                Text("No food entries for this date.")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                List {
                    ForEach(foodEntries) { food in
                        VStack(alignment: .leading) {
                            Text(food.name)
                                .font(.headline)
                            Text("Calories: \(food.calories)")
                            Text("Protein: \(String(format: "%.1f", food.protein))g")
                            Text("Carbs: \(String(format: "%.1f", food.carbs))g")
                            Text("Fats: \(String(format: "%.1f", food.fats))g")
                            Text("Servings: \(food.servings)")
                        }
                        .padding()
                    }
                }
            }
        }
        .onAppear {
            // Debugging
            print("Food entries passed to MacroDetailView: \(foodEntries)")
        }
    }
}
