//
//  MacroHistoryView.swift
//  FoodTrackingApp
//
//  Created by Cem Beyenal on 12/25/24.
//


import SwiftUI


struct MacroHistoryView: View {
    @ObservedObject var viewModel: MacroTrackerViewModel   // ◀︎ observe viewModel so we can grab `history`
    
    var body: some View {
        List {
            ForEach(viewModel.history.sorted(by: { $0.date > $1.date })) { entry in
                NavigationLink {
                    // pass entry.foodsEaten (an array) into FoodLogViewForDate:
                    FoodLogViewForDate(entries: entry.foodsEaten)
                } label: {
                    VStack(alignment: .leading) {
                        Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.headline)
                        Text(
                          "Calories: \(entry.calories), " +
                          "Protein: \(Int(entry.protein.rounded()))g, " +
                          "Carbs: \(Int(entry.carbs.rounded()))g, " +
                          "Fats: \(Int(entry.fats.rounded()))g"
                        )
                        .font(.subheadline)
                    }
                }
            }
        }
        .navigationTitle("History")
    }
}
