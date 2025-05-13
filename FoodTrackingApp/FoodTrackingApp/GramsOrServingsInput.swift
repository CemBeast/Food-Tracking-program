//
//  GramsOrServingsInput.swift
//  FoodTrackingApp
//
//  Created by Cem Beyenal on 11/28/24.
//
import SwiftUI

struct GramsOrServingsInput: View {
    @Environment(\.dismiss) private var dismiss // to dismiss parent view resetting everything
    var food: FoodItem
    let mode: MeasurementMode
    @Binding var gramsOrServings: Int?
    @Binding var showGramsInput: Bool
    
    var updateMacros: (Double, Double, Double, Double) -> Void // Closure to update macros

    let numberFormatter: NumberFormatter = {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.minimumFractionDigits = 0
        nf.maximumFractionDigits = 1
        return nf
    }()
    
    var body: some View {
        VStack {
            Text("Enter \(mode == .serving ? "Servings" : "Grams")")
                .font(.title)

            // input field
            TextField(
                mode == .serving ? "0" : "0",
                value: $gramsOrServings,
                formatter: numberFormatter
            )
            .keyboardType(.numberPad)
            .padding()
            .textFieldStyle(RoundedBorderTextFieldStyle())

            Button(action: updateFoodTracking) {
                Text("Done")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(CustomButtonStyle())
        }
        .padding()
    }

    func updateFoodTracking() {
        guard let value = gramsOrServings, value > 0 else { return }

        // Calculate the ratio based on servings or weight
        let ratio: Double
        switch mode {
        case .serving:
            ratio = Double(value) / Double(food.servings)
        case .weight:
            ratio = Double(value) / Double(food.weightInGrams)
        }
        // Calculate macros
        let calculatedCalories = ratio * Double(food.calories)
        let calculatedFats = ratio * Double(food.fats)
        let calculatedProtein = ratio * Double(food.protein)
        let calculatedCarbs = ratio * Double(food.carbs)
        
        updateMacros(calculatedCalories, calculatedFats, calculatedProtein, calculatedCarbs)
        dismiss()
    }
}
