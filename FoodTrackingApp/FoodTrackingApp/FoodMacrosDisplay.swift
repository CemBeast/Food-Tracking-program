//
//  FoodMacrosDisplay.swift
//  FoodTrackingApp
//
//  Created by Cem Beyenal on 11/18/24.
//
import SwiftUI

struct FoodMacrosDisplay: View {
    var calories: Int
    var protein: Double
    var carbs: Double
    var fats: Double
    
    var body: some View {
        HStack {
            Text("Calories: \(calories)")
            Text("Protein: \(protein, specifier: "%.1f")g")
            Text("Carbs: \(carbs, specifier: "%.1f")g")
            Text("Fats: \(fats, specifier: "%.1f")g")
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(10)
    }
}
