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
        HStack(spacing: 20) { // Add spacing between columns
                    VStack {
                        Text("Calories")
                            .font(.callout) // Smaller font for label
                            .foregroundColor(.gray)
                        Text("\(calories)")
                            .font(.headline) // Larger font for value
                    }
                    .frame(maxWidth: .infinity)
                    VStack {
                        Text("Protein")
                            .font(.callout)
                            .foregroundColor(.gray)
                        Text("\(protein, specifier: "%.1f")g")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    VStack {
                        Text("Carbs")
                            .font(.callout)
                            .foregroundColor(.gray)
                        Text("\(carbs, specifier: "%.1f")g")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    VStack {
                        Text("Fats")
                            .font(.callout)
                            .foregroundColor(.gray)
                        Text("\(fats, specifier: "%.1f")g")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
    }
}
