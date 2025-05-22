//
//  FoodLogView.swift
//  FoodTrackingApp
//
//  Created by Cem Beyenal on 5/21/25.
//
import SwiftUI

struct FoodLogView: View {
    let foods: [FoodItem]

    var body: some View {
        List(foods) { food in
            VStack(alignment: .leading) {
                Text(food.name).font(.headline)
                HStack {
                    Text("Calories: \(food.calories)")
                    Spacer()
                    Text("Protein: \(String(format: "%.1f", food.protein))g")
                    Text("Carbs: \(String(format: "%.1f", food.carbs))g")
                    Text("Fats: \(String(format: "%.1f", food.fats))g")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .navigationTitle("Today's Food Log")
    }
}
