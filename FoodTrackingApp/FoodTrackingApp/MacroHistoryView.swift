//
//  MacroHistoryView.swift
//  FoodTrackingApp
//
//  Created by Cem Beyenal on 12/25/24.
//


import SwiftUI

struct MacroHistoryView: View {
    let history: [MacroHistoryEntry]
    
    var body: some View {
        List(history.sorted(by: {$0.date > $1.date})) { entry in
            VStack(alignment: .leading) {
                Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.headline)
                Text("Calories: \(entry.calories), Protein: \(Int(entry.protein.rounded()))g, Carbs: \(Int(entry.carbs.rounded()))g, Fats: \(Int(entry.fats.rounded()))g")
                    .font(.subheadline)
            }
        }
        .navigationTitle("")
    }
}
