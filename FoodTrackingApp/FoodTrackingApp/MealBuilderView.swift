//
//  MealBuilderView.swift
//  FoodTrackingApp
//
//  Created for meal creation from existing foods
//

import SwiftUI

struct MealComponent: Identifiable {
    let id = UUID()
    let food: FoodItem
    let quantity: Double
    let mode: MeasurementMode
    
    var ratio: Double {
        switch mode {
        case .serving:
            return quantity / Double(max(food.servings, 1))
        case .weight:
            return quantity / Double(max(food.weightInGrams, 1))
        }
    }
    
    var calories: Double { ratio * Double(food.calories) }
    var protein: Double { ratio * food.protein }
    var carbs: Double { ratio * food.carbs }
    var fats: Double { ratio * food.fats }
}

struct MealBuilderView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var foodModel: FoodModel
    
    // Meal data
    @State private var mealName: String = ""
    @State private var components: [MealComponent] = []
    
    // Selection flow
    @State private var showFoodSelection = false
    @State private var selectedFood: FoodItem? = nil
    @State private var selectedFoodID: UUID?
    @State private var selectedMeasurementMode: MeasurementMode?
    @State private var showGramsInput = false
    @State private var gramsOrServings: Double? = nil
    
    private var totalCalories: Int {
        Int(components.reduce(0) { $0 + $1.calories }.rounded())
    }
    private var totalProtein: Double {
        components.reduce(0) { $0 + $1.protein }
    }
    private var totalCarbs: Double {
        components.reduce(0) { $0 + $1.carbs }
    }
    private var totalFats: Double {
        components.reduce(0) { $0 + $1.fats }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        VStack(spacing: 8) {
                            Text("Create a Meal")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary)
                            Text("Combine foods to save as a meal")
                                .font(.system(size: 14))
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        .padding(.top, 16)
                        
                        // Meal name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Meal Name")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(AppTheme.textSecondary)
                            ThemedTextField(placeholder: "e.g., Chicken & Rice Bowl", text: $mealName)
                        }
                        
                        // Components list
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Foods in Meal")
                            
                            if components.isEmpty {
                                Text("No foods added yet")
                                    .font(.system(size: 14))
                                    .foregroundColor(AppTheme.textSecondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(AppTheme.cardBackground)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 14)
                                                    .stroke(AppTheme.border, lineWidth: 1)
                                            )
                                    )
                            } else {
                                VStack(spacing: 10) {
                                    ForEach(components) { comp in
                                        HStack(alignment: .top, spacing: 12) {
                                            VStack(alignment: .leading, spacing: 6) {
                                                Text(comp.food.name)
                                                    .font(.system(size: 15, weight: .semibold))
                                                    .foregroundColor(AppTheme.textPrimary)
                                                
                                                Text(comp.mode == .serving ?
                                                     String(format: "%.1f serving%@", comp.quantity, comp.quantity > 1 ? "s" : "") :
                                                     String(format: "%.0f %@", comp.quantity, comp.food.servingUnit.rawValue))
                                                .font(.system(size: 12))
                                                .foregroundColor(AppTheme.textSecondary)
                                                
                                                HStack(spacing: 6) {
                                                    MacroPill(value: "\(Int(comp.calories.rounded()))", label: "cal", color: AppTheme.calorieColor)
                                                    MacroPill(value: String(format: "%.0f", comp.protein), label: "P", color: AppTheme.proteinColor)
                                                    MacroPill(value: String(format: "%.0f", comp.carbs), label: "C", color: AppTheme.carbColor)
                                                    MacroPill(value: String(format: "%.0f", comp.fats), label: "F", color: AppTheme.fatColor)
                                                }
                                            }
                                            
                                            Spacer()
                                            
                                            Button {
                                                if let idx = components.firstIndex(where: { $0.id == comp.id }) {
                                                    components.remove(at: idx)
                                                }
                                            } label: {
                                                Image(systemName: "trash")
                                                    .foregroundColor(.red)
                                            }
                                        }
                                        .padding()
                                        .background(
                                            RoundedRectangle(cornerRadius: 14)
                                                .fill(AppTheme.cardBackground)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 14)
                                                        .stroke(AppTheme.border, lineWidth: 1)
                                                )
                                        )
                                    }
                                }
                            }
                            
                            Button {
                                showFoodSelection = true
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 18))
                                    Text("Add Food from Dictionary")
                                }
                            }
                            .buttonStyle(SleekButtonStyle())
                        }
                        
                        // Totals
                        VStack(spacing: 8) {
                            Text("Meal Totals")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(AppTheme.textTertiary)
                                .tracking(1.1)
                            
                            HStack(spacing: 8) {
                                MacroPill(value: "\(totalCalories)", label: "cal", color: AppTheme.calorieColor)
                                MacroPill(value: String(format: "%.0f", totalProtein), label: "P", color: AppTheme.proteinColor)
                                MacroPill(value: String(format: "%.0f", totalCarbs), label: "C", color: AppTheme.carbColor)
                                MacroPill(value: String(format: "%.0f", totalFats), label: "F", color: AppTheme.fatColor)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(AppTheme.cardBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(AppTheme.border, lineWidth: 1)
                                )
                        )
                        
                        // Save button
                        Button {
                            saveMeal()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "square.and.arrow.down")
                                    .font(.system(size: 18))
                                Text("Save Meal to Dictionary")
                            }
                        }
                        .buttonStyle(SleekButtonStyle(isSecondary: components.isEmpty))
                        .disabled(components.isEmpty)
                        .opacity(components.isEmpty ? 0.6 : 1.0)
                        
                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Create Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            // Dictionary selection
            .sheet(
                isPresented: $showFoodSelection,
                onDismiss: {
                    selectedFood = nil
                    selectedFoodID = nil
                    selectedMeasurementMode = nil
                    showGramsInput = false
                    gramsOrServings = nil
                }
            ) {
                ZStack {
                    DictionaryView(
                        selectedFood: $selectedFood,
                        showGramsInput: $showGramsInput,
                        selectedFoodID: $selectedFoodID,
                        selectedMeasurementMode: $selectedMeasurementMode,
                        foodModel: foodModel,
                        readOnly: false
                    )
                    if showGramsInput,
                       let food = selectedFood,
                       let mode = selectedMeasurementMode
                    {
                        GramsOrServingsInput(
                            food: food,
                            mode: mode,
                            gramsOrServings: $gramsOrServings,
                            showGramsInput: $showGramsInput,
                            updateMacros: { _, _, _, _ in
                                let actualQuantity = gramsOrServings ?? 0.0
                                let component = MealComponent(food: food, quantity: actualQuantity, mode: mode)
                                components.append(component)
                            }
                        )
                    }
                }
                .onChange(of: showGramsInput) { done in
                    if done == false {
                        selectedFood = nil
                        selectedFoodID = nil
                        selectedMeasurementMode = nil
                    }
                }
            }
        }
    }
    
    private func saveMeal() {
        guard !components.isEmpty else { return }
        let nameToUse = mealName.isEmpty ? "Custom Meal" : mealName
        
        let newMeal = FoodItem(
            name: nameToUse,
            weightInGrams: 0,
            servings: 1,
            calories: totalCalories,
            protein: totalProtein,
            carbs: totalCarbs,
            fats: totalFats,
            servingUnit: .grams,
            isFavorite: false,
            isMeal: true
        )
        
        foodModel.add(newMeal)
        dismiss()
    }
}

