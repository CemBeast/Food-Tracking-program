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
    @State private var numberInput: String = ""
    @FocusState private var isTextFieldFocused: Bool
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
        var liveCalories: Double { inputRatio * Double(food.calories) }
        var liveFats: Double { inputRatio * Double(food.fats) }
        var liveProtein: Double { inputRatio * Double(food.protein) }
        var liveCarbs: Double { inputRatio * Double(food.carbs) }
        
        var parsedInput: Double {
            Double(numberInput) ?? 0
        }
        
        var inputRatio: Double {
            switch mode {
            case .serving:
                return parsedInput / Double(food.servings)
            case .weight:
                return parsedInput / Double(food.weightInGrams)
            }
        }
        
        ZStack {
            // Background
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Title
                if (mode == .serving) {
                    Text("Enter Servings")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                else {
                    Text("Enter Amount in \(food.servingUnit == .grams ? "Grams" : "Milliliters")")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                

                // Card-style input box
                VStack(spacing: 16) {
                    TextField("", text: $numberInput)
                        .keyboardType(.decimalPad)
                        .focused($isTextFieldFocused)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.black)
                        .onChange(of: numberInput) { newValue in
                            let filtered = newValue.filter { $0.isNumber }
                            numberInput = filtered
                            gramsOrServings = Int(filtered)
                        }
                    
                    VStack(spacing: 8) {
                        Text(food.name)
                        Text("Calories: \(Int(liveCalories)) kcal")
                        Text("Fats: \(String(format: "%.1f", liveFats)) g")
                        Text("Protein: \(String(format: "%.1f", liveProtein)) g")
                        Text("Carbs: \(String(format: "%.1f", liveCarbs)) g")
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .transition(.opacity)

                    Button("Confirm") {
                        updateFoodTracking()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(16)
                .shadow(radius: 5)
                .frame(maxWidth: 300)
            }
            .padding()
        }
        .task {
            isTextFieldFocused = true
        }
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
