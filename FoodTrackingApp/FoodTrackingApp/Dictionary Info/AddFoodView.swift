//
//  AddFoodView.swift
//  FoodTrackingApp
//
//  Created by Cem Beyenal on 5/8/25.
//
import SwiftUI
import UIKit


struct AddFoodView: View {
    @Environment(\.presentationMode) var presentationMode

    var onAdd: (FoodItem) -> Void

    @State private var name = ""
    @State private var weightInGrams = ""
    @State private var servings = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fats = ""
    @State private var selectedUnit: ServingUnit = .grams

    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        // Food Info Section
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "Food Info")
                            
                            VStack(spacing: 12) {
                                // Name
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Name")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(AppTheme.textSecondary)
                                    ThemedTextField(placeholder: "Enter food name", text: $name)
                                }
                                
                                // Unit Picker
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Measurement Unit")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(AppTheme.textSecondary)
                                    
                                    HStack(spacing: 8) {
                                        ForEach(ServingUnit.allCases) { unit in
                                            Button {
                                                selectedUnit = unit
                                            } label: {
                                                Text(unit.rawValue.uppercased())
                                                    .font(.system(size: 14, weight: .semibold))
                                                    .foregroundColor(selectedUnit == unit ? .black : AppTheme.textSecondary)
                                                    .frame(maxWidth: .infinity)
                                                    .padding(.vertical, 12)
                                                    .background(
                                                        RoundedRectangle(cornerRadius: 10)
                                                            .fill(selectedUnit == unit ? Color.white : Color.white.opacity(0.06))
                                                    )
                                            }
                                        }
                                    }
                                }
                                
                                // Weight/Volume
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(selectedUnit == .grams ? "Weight (g)" : "Volume (ml)")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(AppTheme.textSecondary)
                                    ThemedTextField(placeholder: "0", text: $weightInGrams, keyboardType: .numberPad)
                                }
                                
                                // Servings
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Servings")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(AppTheme.textSecondary)
                                    ThemedTextField(placeholder: "0", text: $servings, keyboardType: .numberPad)
                                }
                            }
                            .cardStyle()
                        }
                        
                        // Nutrition Section
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "Nutrition")
                            
                            VStack(spacing: 12) {
                                // Calories
                                HStack {
                                    HStack(spacing: 8) {
                                        Circle()
                                            .fill(AppTheme.calorieColor)
                                            .frame(width: 8, height: 8)
                                        Text("Calories")
                                            .font(.system(size: 15))
                                            .foregroundColor(AppTheme.textPrimary)
                                    }
                                    Spacer()
                                    TextField("0", text: $calories)
                                        .keyboardType(.numberPad)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(AppTheme.textPrimary)
                                        .multilineTextAlignment(.trailing)
                                        .frame(width: 100)
                                }
                                
                                Divider().background(AppTheme.divider)
                                
                                // Protein
                                HStack {
                                    HStack(spacing: 8) {
                                        Circle()
                                            .fill(AppTheme.proteinColor)
                                            .frame(width: 8, height: 8)
                                        Text("Protein (g)")
                                            .font(.system(size: 15))
                                            .foregroundColor(AppTheme.textPrimary)
                                    }
                                    Spacer()
                                    TextField("0", text: $protein)
                                        .keyboardType(.decimalPad)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(AppTheme.textPrimary)
                                        .multilineTextAlignment(.trailing)
                                        .frame(width: 100)
                                }
                                
                                Divider().background(AppTheme.divider)
                                
                                // Carbs
                                HStack {
                                    HStack(spacing: 8) {
                                        Circle()
                                            .fill(AppTheme.carbColor)
                                            .frame(width: 8, height: 8)
                                        Text("Carbs (g)")
                                            .font(.system(size: 15))
                                            .foregroundColor(AppTheme.textPrimary)
                                    }
                                    Spacer()
                                    TextField("0", text: $carbs)
                                        .keyboardType(.decimalPad)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(AppTheme.textPrimary)
                                        .multilineTextAlignment(.trailing)
                                        .frame(width: 100)
                                }
                                
                                Divider().background(AppTheme.divider)
                                
                                // Fats
                                HStack {
                                    HStack(spacing: 8) {
                                        Circle()
                                            .fill(AppTheme.fatColor)
                                            .frame(width: 8, height: 8)
                                        Text("Fats (g)")
                                            .font(.system(size: 15))
                                            .foregroundColor(AppTheme.textPrimary)
                                    }
                                    Spacer()
                                    TextField("0", text: $fats)
                                        .keyboardType(.decimalPad)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(AppTheme.textPrimary)
                                        .multilineTextAlignment(.trailing)
                                        .frame(width: 100)
                                }
                            }
                            .cardStyle()
                        }
                        
                        // Add Button
                        Button {
                            if let newFood = saveFoodFromMacros(name: name, weightInGrams: weightInGrams, servings: servings, calories: calories, protein: protein, carbs: carbs, fats: fats, servingUnit: selectedUnit){
                                onAdd(newFood)
                                presentationMode.wrappedValue.dismiss()
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 18))
                                Text("Add Food")
                            }
                        }
                        .disabled(!isFormValid)
                        .buttonStyle(SleekButtonStyle())
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
            }
            .navigationTitle("Add Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(AppTheme.textPrimary)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                UIApplication.shared.endEditing()
            }
        }
    }
    
    // bool var to check if all the fields are filled and valid
    var isFormValid: Bool {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let weight = Int(weightInGrams), weight > 0,
              let servingsInt = Int(servings), servingsInt > 0,
              let cal = Int(calories), cal > 0,
              let prot = Double(protein), prot >= 0,
              let carb = Double(carbs), carb >= 0,
              let fat = Double(fats), fat >= 0
        else { return false }

        return true
    }
    
    // Helper func to save food details into FoodItem
    func saveFoodFromMacros(name: String, weightInGrams: String, servings: String, calories: String, protein: String, carbs: String, fats: String, servingUnit: ServingUnit) -> FoodItem? {
            guard !name.trimmingCharacters(in: .whitespaces).isEmpty,
                  let weight = Int(weightInGrams),
                  let serving = Int(servings),
                  let cal = Int(calories),
                  let pro = Double(protein),
                  let carb = Double(carbs),
                  let fat = Double(fats),
                  cal > 0,
                  pro >= 0.0,
                  carb >= 0.0,
                  fat >= 0.0
            else {
                return nil
            }
        return FoodItem(name: name, weightInGrams: weight, servings: serving, calories: cal, protein: pro, carbs: carb, fats: fat, servingUnit: servingUnit)
        }
}
