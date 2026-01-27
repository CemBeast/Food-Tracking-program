//
//  IngredientsView.swift
//  FoodTrackingApp
//
//  View and edit ingredients of a saved meal
//

import SwiftUI

struct IngredientsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var foodModel: FoodModel

    let mealId: UUID
    var initialMeal: FoodItem?
    var onSave: (FoodItem) -> Void

    @State private var meal: FoodItem? = nil
    @State private var selectedIngredient: MealIngredient? = nil
    @State private var editedQuantity: String = ""
    @State private var isEditingWeight: Bool = false
    @State private var editedTotalWeight: String = ""

    private var ingredients: [MealIngredient] { meal?.ingredients ?? [] }

    private var totals: (cal: Int, protein: Double, carbs: Double, fats: Double, weight: Double)? {
        guard !ingredients.isEmpty else { return nil }
        var c = 0
        var p = 0.0
        var cb = 0.0
        var f = 0.0
        var w = 0.0
        for ing in ingredients {
            let ratio = ratioFor(ing)
            c += Int(Double(ing.calories) * ratio)
            p += ing.protein * ratio
            cb += ing.carbs * ratio
            f += ing.fats * ratio
            w += ingredientWeight(ing)
        }
        return (c, p, cb, f, w)
    }
    
    private var hasIngredients: Bool { !ingredients.isEmpty }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if let meal {
                    listView(meal: meal)
                } else {
                    ProgressView("Loading meal…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle(meal?.name ?? "Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundColor(AppTheme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        guard let meal else { return }
                        let updated = updateMealTotals(meal)
                        onSave(updated)
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .disabled(!hasIngredients)
                }
            }
            .sheet(item: $selectedIngredient) { ing in
                quantityEditor(for: ing)
            }
            .sheet(isPresented: $isEditingWeight) {
                weightEditor()
            }
        }
        .onAppear(perform: loadLatestMealData)
    }
    
    private func listView(meal: FoodItem) -> some View {
        List {
            Section {
                if let totals = totals {
                    HStack(spacing: 8) {
                        MacroPill(value: "\(totals.cal)", label: "cal", color: AppTheme.calorieColor)
                        MacroPill(value: String(format: "%.0f", totals.protein), label: "P", color: AppTheme.proteinColor)
                        MacroPill(value: String(format: "%.0f", totals.carbs), label: "C", color: AppTheme.carbColor)
                        MacroPill(value: String(format: "%.0f", totals.fats), label: "F", color: AppTheme.fatColor)
                        Button {
                            isEditingWeight = true
                            editedTotalWeight = String(format: "%.0f", totals.weight)
                        } label: {
                            MacroPill(value: String(format: "%.0f g", totals.weight), label: "wt", color: AppTheme.textSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    Text("No ingredients yet. Add or recreate this meal to populate ingredients.")
                        .foregroundColor(AppTheme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                }
            } header: {
                Text("Meal totals").foregroundColor(AppTheme.textSecondary)
            }
            .listRowBackground(Color.clear)
            
            Section {
                if  !ingredients.isEmpty {
                    ForEach(ingredients) { ing in
                        ingredientRow(ing)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedIngredient = ing
                                editedQuantity = String(format: "%.1f", ing.quantity)
                            }
                    }
                } else {
                    Text("No ingredients saved for this meal.")
                        .foregroundColor(AppTheme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 12)
                }
            } header: {
                Text("Ingredients").foregroundColor(AppTheme.textSecondary)
            }
            .listRowBackground(Color.clear)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }
    
    private func ingredientRow(_ ing: MealIngredient) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(ing.name)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)
            
            Text(ing.mode == .serving ?
                 String(format: "%.1f serving%@", ing.quantity, ing.quantity > 1 ? "s" : "") :
                 String(format: "%.0f %@", ing.quantity, ing.servingUnit.rawValue))
            .font(.system(size: 12))
            .foregroundColor(AppTheme.textSecondary)
            
            HStack(spacing: 6) {
                let ratio = ratioFor(ing)
                MacroPill(value: "\(Int(Double(ing.calories) * ratio))", label: "cal", color: AppTheme.calorieColor)
                MacroPill(value: String(format: "%.0f", ing.protein * ratio), label: "P", color: AppTheme.proteinColor)
                MacroPill(value: String(format: "%.0f", ing.carbs * ratio), label: "C", color: AppTheme.carbColor)
                MacroPill(value: String(format: "%.0f", ing.fats * ratio), label: "F", color: AppTheme.fatColor)
            }
        }
    }
    
    private func quantityEditor(for ing: MealIngredient) -> some View {
        VStack(spacing: 20) {
            Text("Edit Quantity")
                .font(.title3.bold())
                .padding(.top, 12)
            
            Text(ing.name)
                .font(.headline)
            
            TextField("Quantity", text: $editedQuantity)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
            
            Text(ing.mode == .serving ? "servings" : ing.servingUnit.rawValue)
                .foregroundColor(.secondary)
            
            Button("Save") {
                if let val = Double(editedQuantity), val > 0 {
                    updateIngredient(ing, newQuantity: val)
                    selectedIngredient = nil
                }
            }
            .buttonStyle(.borderedProminent)
            
            Button("Cancel") {
                selectedIngredient = nil
            }
            .foregroundColor(.red)
            
            Spacer()
        }
        .padding()
        .presentationDetents([.medium])
    }
    
    private func weightEditor() -> some View {
        VStack(spacing: 20) {
            Text("Edit Total Weight")
                .font(.title3.bold())
                .padding(.top, 12)

            TextField("Total grams", text: $editedTotalWeight)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)

            Text("grams")
                .foregroundColor(.secondary)

            Button("Save") {
                if let newWeight = Double(editedTotalWeight), newWeight > 0 {
                    applyNewTotalWeight(newWeight)
                    isEditingWeight = false
                }
            }
            .buttonStyle(.borderedProminent)

            Button("Cancel") {
                isEditingWeight = false
            }
            .foregroundColor(.red)

            Spacer()
        }
        .padding()
        .presentationDetents([.medium])
    }
    
    private func updateIngredient(_ ing: MealIngredient, newQuantity: Double) {
        guard var currentMeal = meal else { return }
        var list = currentMeal.ingredients
        if let idx = list.firstIndex(where: { $0.id == ing.id }) {
            var updated = ing
            updated.quantity = newQuantity
            list[idx] = updated
            currentMeal.ingredients = list
            self.meal = currentMeal
        }
    }
    
    private func ratioFor(_ ing: MealIngredient) -> Double {
        switch ing.mode {
        case .serving:
            return newRatio(divisor: Double(max(ing.baseServings, 1)), quantity: ing.quantity)
        case .weight:
            return newRatio(divisor: Double(max(ing.baseWeightInGrams, 1)), quantity: ing.quantity)
        }
    }
    
    private func newRatio(divisor: Double, quantity: Double) -> Double {
        guard divisor > 0 else { return 0 }
        return quantity / divisor
    }
    
    private func updateMealTotals(_ meal: FoodItem) -> FoodItem {
        guard let totals = totals else { return meal }
        var updated = meal
        updated.calories = totals.cal
        updated.protein = totals.protein
        updated.carbs = totals.carbs
        updated.fats = totals.fats
        updated.weightInGrams = Int(totals.weight.rounded())
        updated.ingredients = ingredients
        return updated
    }
    
    private func ingredientWeight(_ ing: MealIngredient) -> Double {
        switch ing.mode {
        case .weight:
            return ing.quantity
        case .serving:
            let base = Double(max(ing.baseWeightInGrams, 0))
            let servings = Double(max(ing.baseServings, 1))
            return servings > 0 ? (base / servings) * ing.quantity : 0
        }
    }
    
    private func applyNewTotalWeight(_ newWeight: Double) {
        guard var currentMeal = meal else { return }
        let currentWeight = totals?.weight ?? 0
        guard currentWeight > 0 else { return }
        let scale = newWeight / currentWeight

        var newIngredients: [MealIngredient] = []
        newIngredients.reserveCapacity(currentMeal.ingredients.count)

        for var ing in currentMeal.ingredients {
            // For both serving and weight modes, scale the quantity proportionally so total weight scales.
            let newQuantity = ing.quantity * scale
            // Prevent zeroing out due to tiny scale; clamp to a minimal positive value if needed
            ing.quantity = max(newQuantity, 0.0001)
            newIngredients.append(ing)
        }

        currentMeal.ingredients = newIngredients
        // Update local state; totals will recompute from ingredients
        self.meal = currentMeal
    }
    
    private func loadLatestMealData() {
        if let found = foodModel.items.first(where: { $0.id == mealId }) {
            meal = found
            print("🧩 Loaded meal ingredients:", found.ingredients.count)
        } else {
            print("⚠️ Meal not found for id \(mealId)")
        }
    }
}

