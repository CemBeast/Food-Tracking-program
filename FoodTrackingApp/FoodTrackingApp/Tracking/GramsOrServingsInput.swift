//
//  GramsOrServingsInput.swift
//  FoodTrackingApp
//
//  Created by Cem Beyenal on 11/28/24.
//
import SwiftUI

struct GramsOrServingsInput: View {
    @Environment(\.dismiss) private var dismiss
    var food: FoodItem
    let mode: MeasurementMode
    @State private var numberInput: String = ""
    @FocusState private var isTextFieldFocused: Bool
    @Binding var gramsOrServings: Double?
    @Binding var showGramsInput: Bool
    var currentMacros: (calories: Int, protein: Double, carbs: Double, fats: Double)? = nil
    
    var updateMacros: (Double, Double, Double, Double) -> Void

    let numberFormatter: NumberFormatter = {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.minimumFractionDigits = 0
        nf.maximumFractionDigits = 1
        return nf
    }()
    
    var body: some View {
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
        
        var liveCalories: Double { inputRatio * Double(food.calories) }
        var liveFats: Double { inputRatio * Double(food.fats) }
        var liveProtein: Double { inputRatio * Double(food.protein) }
        var liveCarbs: Double { inputRatio * Double(food.carbs) }
        
        var totalCalories: Int? {
            guard let current = currentMacros else { return nil }
            return current.calories + Int(liveCalories.rounded())
        }
        var totalProtein: Double? {
            guard let current = currentMacros else { return nil }
            return current.protein + liveProtein
        }
        var totalCarbs: Double? {
            guard let current = currentMacros else { return nil }
            return current.carbs + liveCarbs
        }
        var totalFats: Double? {
            guard let current = currentMacros else { return nil }
            return current.fats + liveFats
        }
        
        ZStack {
            // Dimmed background
            Color.black.opacity(0.85)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }

            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text(food.name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Text(mode == .serving ? "Enter Servings" : "Enter \(food.servingUnit == .grams ? "Grams" : "Milliliters")")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.textSecondary)
                }
                
                // Input Field
                HStack {
                    TextField("0", text: $numberInput)
                        .keyboardType(.decimalPad)
                        .focused($isTextFieldFocused)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.textPrimary)
                        .multilineTextAlignment(.center)
                        .onChange(of: numberInput) { newValue in
                            let filtered = newValue.filter { char in
                                char.isNumber || char == "."
                            }
                            let components = filtered.split(separator: ".")
                            if components.count > 2 {
                                let firstPart = components[0]
                                let secondPart = components.dropFirst().joined(separator: "")
                                numberInput = firstPart + "." + secondPart
                            } else {
                                numberInput = filtered
                            }
                            
                            if let parsed = Double(numberInput) {
                                gramsOrServings = parsed
                            } else {
                                gramsOrServings = nil
                            }
                        }
                    
                    Text(mode == .serving ? "srv" : food.servingUnit.rawValue)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(AppTheme.textTertiary)
                }
                .padding(.horizontal, 32)
                
                // Live Preview
                VStack(spacing: 16) {
                    Text("NUTRITION PREVIEW")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(1.2)
                        .foregroundColor(AppTheme.textTertiary)
                    
                    HStack(spacing: 12) {
                        LiveMacroPill(value: "\(Int(liveCalories))", label: "cal", color: AppTheme.calorieColor)
                        LiveMacroPill(value: String(format: "%.0f", liveProtein), label: "P", color: AppTheme.proteinColor)
                        LiveMacroPill(value: String(format: "%.0f", liveCarbs), label: "C", color: AppTheme.carbColor)
                        LiveMacroPill(value: String(format: "%.0f", liveFats), label: "F", color: AppTheme.fatColor)
                    }
                    
                    if let totalCalories,
                       let totalProtein,
                       let totalCarbs,
                       let totalFats {
                        Text("TOTAL IF ADDED")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(1.1)
                            .foregroundColor(AppTheme.textTertiary)
                        
                        HStack(spacing: 12) {
                            LiveMacroPill(value: "\(totalCalories)", label: "cal", color: AppTheme.calorieColor)
                            LiveMacroPill(value: String(format: "%.0f", totalProtein), label: "P", color: AppTheme.proteinColor)
                            LiveMacroPill(value: String(format: "%.0f", totalCarbs), label: "C", color: AppTheme.carbColor)
                            LiveMacroPill(value: String(format: "%.0f", totalFats), label: "F", color: AppTheme.fatColor)
                        }
                    }
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.05))
                )
                
                // Confirm Button
                Button {
                    updateFoodTracking()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                        Text("Add to Log")
                    }
                }
                .buttonStyle(SleekButtonStyle())
                .padding(.horizontal, 20)
                
                // Cancel Button
                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                }
                .padding(.top, 4)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(AppTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(AppTheme.border, lineWidth: 1)
                    )
            )
            .padding(.horizontal, 24)
        }
        .task {
            isTextFieldFocused = true
        }
    }

    func updateFoodTracking() {
        guard let value = gramsOrServings, value > 0 else { return }

        let ratio: Double
        switch mode {
        case .serving:
            ratio = Double(value) / Double(food.servings)
        case .weight:
            ratio = Double(value) / Double(food.weightInGrams)
        }
        
        let calculatedCalories = ratio * Double(food.calories)
        let calculatedFats = ratio * Double(food.fats)
        let calculatedProtein = ratio * Double(food.protein)
        let calculatedCarbs = ratio * Double(food.carbs)
        
        updateMacros(calculatedCalories, calculatedFats, calculatedProtein, calculatedCarbs)
        dismiss()
    }
}

// MARK: - Live Macro Pill
struct LiveMacroPill: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(color.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.12))
        )
    }
}
