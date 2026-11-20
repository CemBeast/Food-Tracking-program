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
                    VStack(spacing: 24.scaled) {
                        // Food Info Section
                        VStack(alignment: .leading, spacing: 16.scaled) {
                            SectionHeader(title: "Food Info")
                            
                            VStack(spacing: 12.scaled) {
                                // Name
                                VStack(alignment: .leading, spacing: 6.scaled) {
                                    Text("Name")
                                        .font(.system(size: 13.scaled, weight: .medium))
                                        .foregroundColor(AppTheme.textSecondary)
                                    ThemedTextField(placeholder: "Enter food name", text: $name)
                                }
                                
                                // Unit Picker
                                VStack(alignment: .leading, spacing: 6.scaled) {
                                    Text("Measurement Unit")
                                        .font(.system(size: 13.scaled, weight: .medium))
                                        .foregroundColor(AppTheme.textSecondary)
                                    
                                    HStack(spacing: 8.scaled) {
                                        ForEach(ServingUnit.allCases) { unit in
                                            Button {
                                                selectedUnit = unit
                                            } label: {
                                                Text(unit.rawValue.uppercased())
                                                    .font(.system(size: 14.scaled, weight: .semibold))
                                                    .foregroundColor(selectedUnit == unit ? .black : AppTheme.textSecondary)
                                                    .frame(maxWidth: .infinity)
                                                    .padding(.vertical, 12.scaled)
                                                    .background(
                                                        RoundedRectangle(cornerRadius: 10.scaled)
                                                            .fill(selectedUnit == unit ? Color.white : Color.white.opacity(0.06))
                                                    )
                                            }
                                        }
                                    }
                                }
                                
                                // Weight/Volume
                                VStack(alignment: .leading, spacing: 6.scaled) {
                                    Text(selectedUnit == .grams ? "Weight (g)" : "Volume (ml)")
                                        .font(.system(size: 13.scaled, weight: .medium))
                                        .foregroundColor(AppTheme.textSecondary)
                                    ThemedTextField(placeholder: "0", text: $weightInGrams, keyboardType: .numberPad)
                                }
                                
                                // Servings
                                VStack(alignment: .leading, spacing: 6.scaled) {
                                    Text("Servings")
                                        .font(.system(size: 13.scaled, weight: .medium))
                                        .foregroundColor(AppTheme.textSecondary)
                                    ThemedTextField(placeholder: "0", text: $servings, keyboardType: .numberPad)
                                }
                            }
                            .cardStyle()
                        }
                        
                        // Nutrition Section
                        VStack(alignment: .leading, spacing: 16.scaled) {
                            SectionHeader(title: "Nutrition")
                            
                            VStack(spacing: 12.scaled) {
                                // Calories
                                HStack {
                                    HStack(spacing: 8.scaled) {
                                        Circle()
                                            .fill(AppTheme.calorieColor)
                                            .frame(width: 8.scaled, height: 8.scaled)
                                        Text("Calories")
                                            .font(.system(size: 15.scaled))
                                            .foregroundColor(AppTheme.textPrimary)
                                    }
                                    Spacer()
                                    TextField("0", text: $calories)
                                        .keyboardType(.numberPad)
                                        .font(.system(size: 16.scaled, weight: .semibold))
                                        .foregroundColor(AppTheme.textPrimary)
                                        .multilineTextAlignment(.trailing)
                                        .frame(width: 100.scaled)
                                }
                                
                                Divider().background(AppTheme.divider)
                                
                                // Protein
                                HStack {
                                    HStack(spacing: 8.scaled) {
                                        Circle()
                                            .fill(AppTheme.proteinColor)
                                            .frame(width: 8.scaled, height: 8.scaled)
                                        Text("Protein (g)")
                                            .font(.system(size: 15.scaled))
                                            .foregroundColor(AppTheme.textPrimary)
                                    }
                                    Spacer()
                                    TextField("0", text: $protein)
                                        .keyboardType(.decimalPad)
                                        .font(.system(size: 16.scaled, weight: .semibold))
                                        .foregroundColor(AppTheme.textPrimary)
                                        .multilineTextAlignment(.trailing)
                                        .frame(width: 100.scaled)
                                }
                                
                                Divider().background(AppTheme.divider)
                                
                                // Carbs
                                HStack {
                                    HStack(spacing: 8.scaled) {
                                        Circle()
                                            .fill(AppTheme.carbColor)
                                            .frame(width: 8.scaled, height: 8.scaled)
                                        Text("Carbs (g)")
                                            .font(.system(size: 15.scaled))
                                            .foregroundColor(AppTheme.textPrimary)
                                    }
                                    Spacer()
                                    TextField("0", text: $carbs)
                                        .keyboardType(.decimalPad)
                                        .font(.system(size: 16.scaled, weight: .semibold))
                                        .foregroundColor(AppTheme.textPrimary)
                                        .multilineTextAlignment(.trailing)
                                        .frame(width: 100.scaled)
                                }
                                
                                Divider().background(AppTheme.divider)
                                
                                // Fats
                                HStack {
                                    HStack(spacing: 8.scaled) {
                                        Circle()
                                            .fill(AppTheme.fatColor)
                                            .frame(width: 8.scaled, height: 8.scaled)
                                        Text("Fats (g)")
                                            .font(.system(size: 15.scaled))
                                            .foregroundColor(AppTheme.textPrimary)
                                    }
                                    Spacer()
                                    TextField("0", text: $fats)
                                        .keyboardType(.decimalPad)
                                        .font(.system(size: 16.scaled, weight: .semibold))
                                        .foregroundColor(AppTheme.textPrimary)
                                        .multilineTextAlignment(.trailing)
                                        .frame(width: 100.scaled)
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
                            HStack(spacing: 8.scaled) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 18.scaled))
                                Text("Add Food")
                            }
                        }
                        .disabled(!isFormValid)
                        .buttonStyle(SleekButtonStyle())
                        .padding(.top, 8.scaled)
                    }
                    .padding(.horizontal, 20.scaled)
                    .padding(.vertical, 24.scaled)
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
