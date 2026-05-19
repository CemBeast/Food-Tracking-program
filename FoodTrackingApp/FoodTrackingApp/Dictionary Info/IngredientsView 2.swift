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
    @State private var editedMealWeight: String = ""
    @State private var showMealWeightEditor = false

    // Delete confirmation (tap-trash only; swipe-delete is immediate)
    @State private var ingredientPendingDelete: MealIngredient? = nil

    // Add-ingredient flow (mirrors MealBuilderView)
    @State private var showFoodSelection = false
    @State private var selectedFood: FoodItem? = nil
    @State private var selectedFoodID: UUID? = nil
    @State private var selectedMeasurementMode: MeasurementMode? = nil
    @State private var showGramsInput = false
    @State private var gramsOrServings: Double? = nil
    @State private var showMeasurementChoice = false

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
                        onSave(meal)
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .disabled(!hasIngredients)
                }
            }
            .sheet(item: $selectedIngredient) { ing in
                quantityEditor(for: ing)
            }
            .sheet(
                isPresented: $showFoodSelection,
                onDismiss: resetFoodSelectionState
            ) {
                foodSelectionSheet
            }
            .alert(
                "Remove \(ingredientPendingDelete?.name ?? "ingredient")?",
                isPresented: deletePromptBinding
            ) {
                Button("Remove", role: .destructive) {
                    if let ing = ingredientPendingDelete {
                        removeIngredient(ing)
                    }
                    ingredientPendingDelete = nil
                }
                Button("Cancel", role: .cancel) {
                    ingredientPendingDelete = nil
                }
            } message: {
                Text("This ingredient will be removed from the meal.")
            }
        }
        .onAppear(perform: loadLatestMealData)
    }

    private var deletePromptBinding: Binding<Bool> {
        Binding(
            get: { ingredientPendingDelete != nil },
            set: { if !$0 { ingredientPendingDelete = nil } }
        )
    }

    @ViewBuilder
    private var foodSelectionSheet: some View {
        ZStack {
            DictionaryView(
                selectedFood: $selectedFood,
                showGramsInput: $showGramsInput,
                selectedFoodID: $selectedFoodID,
                selectedMeasurementMode: $selectedMeasurementMode,
                foodModel: foodModel,
                onFoodSelected: { food in
                    selectedFood = food
                    selectedFoodID = food.id
                    showMeasurementChoice = true
                },
                readOnly: true
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
                        addIngredient(food: food, quantity: actualQuantity, mode: mode)
                    }
                )
            }
        }
        .blur(radius: showMeasurementChoice ? 10 : 0)
        .animation(.easeInOut(duration: 0.2), value: showMeasurementChoice)
        .confirmationDialog(
            "Track by",
            isPresented: $showMeasurementChoice,
            titleVisibility: .visible
        ) {
            if let unit = selectedFood?.servingUnit {
                Button(unit == .milliliters ? "Volume" : "Weight") {
                    selectedMeasurementMode = .weight
                    showGramsInput = true
                }
            }
            Button("Servings") {
                selectedMeasurementMode = .serving
                showGramsInput = true
            }
            Button("Cancel", role: .cancel) {
                selectedFood = nil
                selectedFoodID = nil
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

    private func resetFoodSelectionState() {
        selectedFood = nil
        selectedFoodID = nil
        selectedMeasurementMode = nil
        showGramsInput = false
        gramsOrServings = nil
        showMeasurementChoice = false
    }
    
    private func listView(meal: FoodItem) -> some View {
        List {
            Section {
                if !ingredients.isEmpty {
                    HStack(spacing: 10) {
                        metricTile(
                            title: "Calories",
                            value: "\(meal.calories)",
                            icon: "flame.fill",
                            color: AppTheme.calorieColor
                        )
                        metricTile(
                            title: "Protein",
                            value: String(format: "%.0f", meal.protein),
                            icon: "bolt.circle.fill",
                            color: AppTheme.proteinColor
                        )
                        metricTile(
                            title: "Carbs",
                            value: String(format: "%.0f", meal.carbs),
                            icon: "leaf.circle.fill",
                            color: AppTheme.carbColor
                        )
                        metricTile(
                            title: "Fats",
                            value: String(format: "%.0f", meal.fats),
                            icon: "drop.circle.fill",
                            color: AppTheme.fatColor
                        )
                        Button {
                            editedMealWeight = "\(meal.weightInGrams)"
                            showMealWeightEditor = true
                        } label: {
                            metricTile(
                                title: "Weight",
                                value: "\(meal.weightInGrams) g",
                                icon: "scalemass.fill",
                                color: AppTheme.textSecondary
                            )
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
                if !ingredients.isEmpty {
                    ForEach(ingredients) { ing in
                        ingredientRow(ing)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedIngredient = ing
                                editedQuantity = String(format: "%.0f", ing.quantity)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    removeIngredient(ing)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                } else {
                    Text("No ingredients saved for this meal.")
                        .foregroundColor(AppTheme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 12)
                }

                Button {
                    showFoodSelection = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18))
                        Text("Add Ingredient")
                    }
                }
                .buttonStyle(SleekButtonStyle())
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                .listRowSeparator(.hidden)
            } header: {
                Text("Ingredients").foregroundColor(AppTheme.textSecondary)
            }
            .listRowBackground(Color.clear)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .sheet(isPresented: $showMealWeightEditor) {
            MealWeightEditor(
                mealName: meal.name,
                originalWeightInGrams: meal.weightInGrams,
                weightText: $editedMealWeight,
                onSave: { newWeight in
                    updateMealWeight(newWeight)
                    showMealWeightEditor = false
                },
                onCancel: { showMealWeightEditor = false }
            )
        }
    }
    
    private func ingredientRow(_ ing: MealIngredient) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(ing.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)

                HStack(spacing: 6) {
                    Text(ing.mode == .serving ?
                         String(format: "%.1f serving%@", ing.quantity, ing.quantity > 1 ? "s" : "") :
                         String(format: "%.0f %@", ing.quantity, ing.servingUnit.rawValue))
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textSecondary)
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textSecondary)
                }

                HStack(spacing: 6) {
                    let ratio = ratioFor(ing)
                    MacroPill(value: "\(Int(Double(ing.calories) * ratio))", label: "cal", color: AppTheme.calorieColor)
                    MacroPill(value: String(format: "%.0f", ing.protein * ratio), label: "P", color: AppTheme.proteinColor)
                    MacroPill(value: String(format: "%.0f", ing.carbs * ratio), label: "C", color: AppTheme.carbColor)
                    MacroPill(value: String(format: "%.0f", ing.fats * ratio), label: "F", color: AppTheme.fatColor)
                }
            }

            Spacer()

            Button {
                ingredientPendingDelete = ing
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.red)
                    .padding(8)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
        }
    }
    
    private func quantityEditor(for ing: MealIngredient) -> some View {
        IngredientQuantityEditor(
            ingredient: ing,
            quantityText: $editedQuantity,
            onSave: { newQuantity in
                updateIngredient(ing, newQuantity: newQuantity)
                selectedIngredient = nil
            },
            onCancel: { selectedIngredient = nil }
        )
    }
    
    private func addIngredient(food: FoodItem, quantity: Double, mode: MeasurementMode) {
        guard var meal = meal, quantity > 0 else { return }
        let newIngredient = MealIngredient(
            foodId: food.id,
            name: food.name,
            baseWeightInGrams: food.weightInGrams,
            baseServings: food.servings,
            servingUnit: food.servingUnit,
            calories: food.calories,
            protein: food.protein,
            carbs: food.carbs,
            fats: food.fats,
            quantity: quantity,
            mode: mode
        )
        var list = meal.ingredients
        list.append(newIngredient)
        meal.ingredients = list
        applyTotals(to: &meal, from: list)
        self.meal = meal
    }

    private func removeIngredient(_ ing: MealIngredient) {
        guard var meal = meal else { return }
        var list = meal.ingredients
        list.removeAll { $0.id == ing.id }
        meal.ingredients = list
        applyTotals(to: &meal, from: list)
        self.meal = meal
    }

    private func applyTotals(to meal: inout FoodItem, from list: [MealIngredient]) {
        let totals = computeTotals(from: list)
        meal.calories = totals.cal
        meal.protein = totals.protein
        meal.carbs = totals.carbs
        meal.fats = totals.fats
        meal.weightInGrams = Int(totals.weight.rounded())
    }

    private func updateIngredient(_ ing: MealIngredient, newQuantity: Double) {
        guard var meal = meal else { return }
        var list = meal.ingredients
        if let idx = list.firstIndex(where: { $0.id == ing.id }) {
            var updated = ing
            updated.quantity = newQuantity
            list[idx] = updated
            meal.ingredients = list
            
            // Recalculate totals from updated ingredients
            let newTotals = computeTotals(from: list)
            meal.calories = newTotals.cal
            meal.protein = newTotals.protein
            meal.carbs = newTotals.carbs
            meal.fats = newTotals.fats
            meal.weightInGrams = Int(newTotals.weight.rounded())
            
            self.meal = meal
        }
    }
    
    private func computeTotals(from list: [MealIngredient]) -> (cal: Int, protein: Double, carbs: Double, fats: Double, weight: Double) {
       var c = 0
       var p = 0.0
       var cb = 0.0
       var f = 0.0
       var w = 0.0
       for ing in list {
           let ratio = ratioFor(ing)
           c += Int(Double(ing.calories) * ratio)
           p += ing.protein * ratio
           cb += ing.carbs * ratio
           f += ing.fats * ratio
           w += ingredientWeight(ing)
       }
       return (c, p, cb, f, w)
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
        updated.ingredients = ingredients
        return updated
    }

    private func updateMealWeight(_ newWeight: Int) {
        guard var meal = meal else { return }
        meal.weightInGrams = newWeight
        self.meal = meal
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
    
    private func loadLatestMealData() {
        foodModel.load() // refresh from disk to avoid stale copy
        if let found = foodModel.items.first(where: { $0.id == mealId }) {
            meal = found
            print("🧩 Loaded meal ingredients:", found.ingredients.count)
        } else {
            print("⚠️ Meal not found for id \(mealId)")
        }
    }
    
    private func metricTile(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(color)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
            
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(AppTheme.textSecondary)
                .tracking(0.8)
            
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.15), lineWidth: 1)
                )
        )
    }
}

// MARK: - Ingredient quantity editor

/// Professional quantity-edit sheet for a single ingredient.
///
/// Mirrors the visual language of `GramsOrServingsInput`: a large bold
/// centered numeric field, a live "Nutrition Preview" of the recalculated
/// macros, and a sleek primary save button matching the rest of the app.
private struct IngredientQuantityEditor: View {
    let ingredient: MealIngredient
    @Binding var quantityText: String
    let onSave: (Double) -> Void
    let onCancel: () -> Void

    @FocusState private var isFocused: Bool

    private var parsedQuantity: Double { Double(quantityText) ?? 0 }
    private var canSave: Bool { parsedQuantity > 0 }

    private var unitLabel: String {
        ingredient.mode == .serving ? "srv" : ingredient.servingUnit.rawValue
    }

    private var subtitle: String {
        ingredient.mode == .serving ? "Servings" : "Quantity"
    }

    private var headerIcon: String {
        ingredient.mode == .serving ? "fork.knife" : "scalemass.fill"
    }

    // Live macro recomputation as the user types.
    private var liveRatio: Double {
        let divisor: Double
        switch ingredient.mode {
        case .serving: divisor = Double(max(ingredient.baseServings, 1))
        case .weight:  divisor = Double(max(ingredient.baseWeightInGrams, 1))
        }
        guard divisor > 0 else { return 0 }
        return parsedQuantity / divisor
    }
    private var liveCalories: Int { Int((Double(ingredient.calories) * liveRatio).rounded()) }
    private var liveProtein: Double { ingredient.protein * liveRatio }
    private var liveCarbs:   Double { ingredient.carbs   * liveRatio }
    private var liveFats:    Double { ingredient.fats    * liveRatio }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 24) {
                EditorHeader(
                    icon: headerIcon,
                    accent: AppTheme.calorieColor,
                    title: "Edit Quantity",
                    subtitle: ingredient.name
                )

                LargeNumberField(
                    text: $quantityText,
                    unit: unitLabel,
                    placeholder: "0",
                    caption: subtitle,
                    keyboard: .decimalPad,
                    isFocused: $isFocused
                )

                NutritionPreview(
                    calories: liveCalories,
                    protein: liveProtein,
                    carbs: liveCarbs,
                    fats: liveFats
                )

                Spacer(minLength: 0)

                EditorActions(
                    saveTitle: "Save Changes",
                    canSave: canSave,
                    onSave: { onSave(parsedQuantity) },
                    onCancel: onCancel
                )
            }
            .padding(.horizontal, 24)
            .padding(.top, 28)
            .padding(.bottom, 20)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .task { isFocused = true }
    }
}

// MARK: - Meal weight editor

/// Professional weight-edit sheet for the parent meal. Same chrome as the
/// ingredient editor, but with a delta-aware caption that tells the user how
/// much the new value moves the meal versus its current weight.
private struct MealWeightEditor: View {
    let mealName: String
    let originalWeightInGrams: Int
    @Binding var weightText: String
    let onSave: (Int) -> Void
    let onCancel: () -> Void

    @FocusState private var isFocused: Bool

    private var parsedWeight: Int? {
        guard let n = Int(weightText), n > 0 else { return nil }
        return n
    }
    private var canSave: Bool { parsedWeight != nil }

    private var deltaCaption: String {
        guard let new = parsedWeight else {
            return "Enter the meal's total weight in grams."
        }
        let delta = new - originalWeightInGrams
        if delta == 0 { return "Same as the current weight." }
        let direction = delta > 0 ? "heavier" : "lighter"
        return "\(abs(delta)) g \(direction) than the current \(originalWeightInGrams) g."
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 24) {
                EditorHeader(
                    icon: "scalemass.fill",
                    accent: AppTheme.textPrimary,
                    title: "Edit Meal Weight",
                    subtitle: mealName
                )

                LargeNumberField(
                    text: $weightText,
                    unit: "g",
                    placeholder: "0",
                    caption: "Total weight",
                    keyboard: .numberPad,
                    isFocused: $isFocused
                )
                .onChange(of: weightText) { newValue in
                    // Strip any non-digit characters defensively (number pad
                    // can still receive paste/dictation input).
                    let filtered = newValue.filter(\.isNumber)
                    if filtered != newValue { weightText = filtered }
                }

                Text(deltaCaption)
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                Spacer(minLength: 0)

                EditorActions(
                    saveTitle: "Save Weight",
                    canSave: canSave,
                    onSave: {
                        if let new = parsedWeight { onSave(new) }
                    },
                    onCancel: onCancel
                )
            }
            .padding(.horizontal, 24)
            .padding(.top, 28)
            .padding(.bottom, 20)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .task { isFocused = true }
    }
}

// MARK: - Shared editor chrome

/// Icon badge + title + subtitle stacked at the top of an editor sheet.
private struct EditorHeader: View {
    let icon: String
    let accent: Color
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.15))
                    .frame(width: 56, height: 56)
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(accent)
            }

            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                Text(subtitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
    }
}

/// The bold centered numeric input used by both editors.
private struct LargeNumberField: View {
    @Binding var text: String
    let unit: String
    let placeholder: String
    let caption: String
    let keyboard: UIKeyboardType
    @FocusState.Binding var isFocused: Bool

    var body: some View {
        VStack(spacing: 10) {
            Text(caption.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.2)
                .foregroundColor(AppTheme.textTertiary)

            HStack(alignment: .firstTextBaseline, spacing: 10) {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboard)
                    .focused($isFocused)
                    .multilineTextAlignment(.trailing)
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                Text(unit)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AppTheme.textTertiary)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isFocused ? AppTheme.accent.opacity(0.35) : AppTheme.border,
                                lineWidth: 1
                            )
                    )
            )
            .animation(.easeOut(duration: 0.15), value: isFocused)
        }
    }
}

/// Inline live preview of macros while the user types a new quantity.
private struct NutritionPreview: View {
    let calories: Int
    let protein: Double
    let carbs: Double
    let fats: Double

    var body: some View {
        VStack(spacing: 12) {
            Text("Nutrition Preview".uppercased())
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.2)
                .foregroundColor(AppTheme.textTertiary)

            HStack(spacing: 10) {
                MacroPill(value: "\(calories)",
                          label: "cal",
                          color: AppTheme.calorieColor)
                MacroPill(value: String(format: "%.0f", protein),
                          label: "P",
                          color: AppTheme.proteinColor)
                MacroPill(value: String(format: "%.0f", carbs),
                          label: "C",
                          color: AppTheme.carbColor)
                MacroPill(value: String(format: "%.0f", fats),
                          label: "F",
                          color: AppTheme.fatColor)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(AppTheme.border, lineWidth: 1)
                )
        )
    }
}

/// Save / cancel button stack used at the bottom of every editor sheet.
private struct EditorActions: View {
    let saveTitle: String
    let canSave: Bool
    let onSave: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Button(action: onSave) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 17))
                    Text(saveTitle)
                }
            }
            .buttonStyle(SleekButtonStyle())
            .disabled(!canSave)
            .opacity(canSave ? 1.0 : 0.5)

            Button("Cancel", action: onCancel)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppTheme.textSecondary)
                .padding(.top, 2)
        }
    }
}
