//
//  FoodLogView.swift
//  FoodTrackingApp
//
//  Created by Cem Beyenal on 5/21/25.
//
import SwiftUI

struct FoodLogView: View {
    let foods: [LoggedFoodEntry]

    var body: some View {
        List(foods) { entry in
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.food.name)
                    .font(.headline)

                HStack {
                    Text("Calories: \(entry.food.calories)")
                    Text("Protein: \(String(format: "%.1f", entry.food.protein))g")
                    Text("Carbs: \(String(format: "%.1f", entry.food.carbs))g")
                    Text("Fats: \(String(format: "%.1f", entry.food.fats))g")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)

                Text(entry.mode == .weight
                     ? "\(entry.quantity) \(entry.servingUnit.rawValue)"
                     : "\(entry.quantity) serving\(entry.quantity > 1 ? "s" : "")"
                )
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 6)
        }
        .navigationTitle("Today's Food Log")
    }
}
