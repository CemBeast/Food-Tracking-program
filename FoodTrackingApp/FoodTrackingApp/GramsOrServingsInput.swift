//
//  GramsOrServingsInput.swift
//  FoodTrackingApp
//
//  Created by Cem Beyenal on 11/28/24.
//
import SwiftUI

struct GramsOrServingsInput: View {
    var food: FoodItem
    @Binding var gramsOrServings: Int?
    @Binding var showGramsInput: Bool
    
    var updateMacros: (Double, Double, Double, Double) -> Void // Closure to update macros

    var body: some View {
        VStack {
            Text("Enter \(food.isMeasuredByServing ? "Servings" : "Grams")")
                .font(.title)

            TextField(food.isMeasuredByServing ? "Enter servings" : "Enter grams", value: $gramsOrServings, formatter: NumberFormatter())
                .keyboardType(.numberPad)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())

            Button(action: {
                // Update macros based on the selected food and entered value
                updateFoodTracking()
            }) {
                Text("Done")
                    .buttonStyle(CustomButtonStyle())
            }
        }
        .padding()
    }

    func updateFoodTracking() {
        guard let gramsOrServings = gramsOrServings else { return }

        // Calculate the ratio based on servings or weight
        let ratio: Double
        if food.isMeasuredByServing {
            ratio = Double(gramsOrServings) / Double(food.servings)
        } else {
            ratio = Double(gramsOrServings) / Double(food.weightInGrams)
        }
        // Calculate macros
        let calculatedCalories = ratio * Double(food.calories)
        let calculatedFats = ratio * Double(food.fats)
        let calculatedProtein = ratio * Double(food.protein)
        let calculatedCarbs = ratio * Double(food.carbs)
        
        updateMacros(calculatedCalories, calculatedFats, calculatedProtein, calculatedCarbs)
        
        // After updating, close the modal by setting `showGramsInput` to `false`
        showGramsInput = false  // This will dismiss the view

    }
}
