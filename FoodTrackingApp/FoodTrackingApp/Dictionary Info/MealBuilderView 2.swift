//
//  MealBuilderView.swift
//  FoodTrackingApp
//
//  Created for meal creation from existing foods.
//
//  This view lets the user assemble a "meal" by combining items from the food
//  dictionary, each with its own quantity and measurement mode (weight or
//  serving). The aggregated meal is saved back into the dictionary as a new
//  `FoodItem` with `isMeal == true`.
//
//  The file is organized as:
//    1. MealComponent  – pure value type for one ingredient + quantity.
//    2. MealTotals     – aggregator over [MealComponent].
//    3. MealBuilderView – the screen, decomposed into small section views.
//    4. ComponentRow   – a single ingredient card in the list.
//    5. CardBackground – reusable rounded card chrome.
//    6. FoodPickerSheet – self-contained "pick → choose mode → enter quantity"
//                          flow, isolated from the parent.
//

import SwiftUI

// MARK: - Model

/// One ingredient added to the meal under construction.
///
/// All macro and weight values are derived on demand from the underlying
/// `FoodItem` plus the user-entered `quantity` and `mode`, so a `MealComponent`
/// is a pure, immutable value type.
struct MealComponent: Identifiable {
    let id = UUID()
    let food: FoodItem
    let quantity: Double
    let mode: MeasurementMode

    /// Multiplier applied to the food's stored macros to scale them to the
    /// user-entered quantity. Guards against zero divisors on malformed data.
    private var ratio: Double {
        switch mode {
        case .serving:
            return quantity / Double(max(food.servings, 1))
        case .weight:
            return quantity / Double(max(food.weightInGrams, 1))
        }
    }

    var calories: Double { ratio * Double(food.calories) }
    var protein: Double  { ratio * food.protein }
    var carbs: Double    { ratio * food.carbs }
    var fats: Double     { ratio * food.fats }

    /// Effective weight in grams contributed by this component. For weight
    /// mode this is just the entered quantity; for serving mode we scale the
    /// food's per-portion weight.
    var weightInGrams: Double {
        switch mode {
        case .weight:
            return quantity
        case .serving:
            let baseWeight = Double(max(food.weightInGrams, 0))
            let baseServings = Double(max(food.servings, 1))
            return (baseWeight / baseServings) * quantity
        }
    }

    /// User-facing quantity description, e.g. "1.5 servings" or "200 g".
    var quantityDescription: String {
        switch mode {
        case .serving:
            let plural = quantity > 1 ? "s" : ""
            return String(format: "%.1f serving%@", quantity, plural)
        case .weight:
            return String(format: "%.0f %@", quantity, food.servingUnit.rawValue)
        }
    }
}

private extension MealComponent {
    /// Reconstruct a `MealComponent` from a previously persisted ingredient,
    /// so an existing meal can be loaded into the builder for editing.
    init(ingredient: MealIngredient) {
        let baseFood = FoodItem(
            name: ingredient.name,
            weightInGrams: ingredient.baseWeightInGrams,
            servings: ingredient.baseServings,
            calories: ingredient.calories,
            protein: ingredient.protein,
            carbs: ingredient.carbs,
            fats: ingredient.fats,
            servingUnit: ingredient.servingUnit,
            isFavorite: false,
            isMeal: false,
            ingredients: []
        )
        self.init(food: baseFood, quantity: ingredient.quantity, mode: ingredient.mode)
    }

    /// Snapshot this component as a persistable `MealIngredient`.
    func toIngredient() -> MealIngredient {
        MealIngredient(
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
    }
}

/// Aggregated nutritional totals across an array of components. Computed once
/// per render rather than recomputed for every macro pill.
private struct MealTotals {
    let calories: Int
    let protein: Double
    let carbs: Double
    let fats: Double
    let weightInGrams: Double

    init(components: [MealComponent]) {
        calories      = Int(components.reduce(0) { $0 + $1.calories }.rounded())
        protein       = components.reduce(0) { $0 + $1.protein }
        carbs         = components.reduce(0) { $0 + $1.carbs }
        fats          = components.reduce(0) { $0 + $1.fats }
        weightInGrams = components.reduce(0) { $0 + $1.weightInGrams }
    }
}

// MARK: - Main view

struct MealBuilderView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var foodModel: FoodModel
    var existingMeal: FoodItem?
    var onSave: ((FoodItem) -> Void)?

    init(
        foodModel: FoodModel,
        existingMeal: FoodItem? = nil,
        onSave: ((FoodItem) -> Void)? = nil
    ) {
        self.foodModel = foodModel
        self.existingMeal = existingMeal
        self.onSave = onSave
    }

    // Editable meal data.
    @State private var mealName: String = ""
    @State private var components: [MealComponent] = []

    // Picker-sheet presentation. All transient selection state lives inside
    // FoodPickerSheet, so the parent only tracks whether the sheet is open.
    @State private var isPickerPresented: Bool = false

    private var totals: MealTotals { MealTotals(components: components) }
    private var isEditingExistingMeal: Bool { existingMeal != nil }
    private var canSave: Bool { !components.isEmpty }

    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        header
                        mealNameField
                        componentsSection
                        totalsCard
                        saveButton
                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, 20)
                    .contentShape(Rectangle())
                    .onTapGesture { UIApplication.shared.endEditing() }
                }
            }
            .navigationTitle("Create Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { closeToolbarItem }
            .sheet(isPresented: $isPickerPresented) {
                FoodPickerSheet(foodModel: foodModel) { food, quantity, mode in
                    components.append(
                        MealComponent(food: food, quantity: quantity, mode: mode)
                    )
                }
            }
        }
        .onAppear(perform: loadExistingMealIfNeeded)
    }

    // MARK: - Sections

    private var header: some View {
        VStack(spacing: 8) {
            Text(isEditingExistingMeal ? "Edit Meal" : "Create a Meal")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)
            Text("Combine foods to save as a meal")
                .font(.system(size: 14))
                .foregroundColor(AppTheme.textSecondary)
        }
        .padding(.top, 16)
    }

    private var mealNameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Meal Name")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppTheme.textSecondary)
            ThemedTextField(placeholder: "e.g., Chicken & Rice Bowl", text: $mealName)
        }
    }

    private var componentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Foods in Meal")

            if components.isEmpty {
                emptyComponentsCard
            } else {
                VStack(spacing: 10) {
                    ForEach(components) { component in
                        ComponentRow(component: component) {
                            remove(component)
                        }
                    }
                }
            }

            addFoodButton
        }
    }

    private var emptyComponentsCard: some View {
        Text("No foods added yet")
            .font(.system(size: 14))
            .foregroundColor(AppTheme.textSecondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding()
            .modifier(CardBackground(cornerRadius: 14))
    }

    private var addFoodButton: some View {
        Button {
            isPickerPresented = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18))
                Text("Add Food from Dictionary")
            }
        }
        .buttonStyle(SleekButtonStyle())
    }

    private var totalsCard: some View {
        VStack(spacing: 8) {
            Text("Meal Totals")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppTheme.textTertiary)
                .tracking(1.1)

            HStack(spacing: 8) {
                MacroPill(value: "\(totals.calories)",
                          label: "cal",
                          color: AppTheme.calorieColor)
                MacroPill(value: String(format: "%.0f", totals.protein),
                          label: "P",
                          color: AppTheme.proteinColor)
                MacroPill(value: String(format: "%.0f", totals.carbs),
                          label: "C",
                          color: AppTheme.carbColor)
                MacroPill(value: String(format: "%.0f", totals.fats),
                          label: "F",
                          color: AppTheme.fatColor)
                MacroPill(value: String(format: "%.0f g", totals.weightInGrams),
                          label: "wt",
                          color: AppTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .modifier(CardBackground(cornerRadius: 16))
    }

    private var saveButton: some View {
        Button(action: saveMeal) {
            HStack(spacing: 12) {
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 18))
                Text("Save Meal to Dictionary")
            }
        }
        .buttonStyle(SleekButtonStyle(isSecondary: !canSave))
        .disabled(!canSave)
        .opacity(canSave ? 1.0 : 0.6)
    }

    private var closeToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Close") { dismiss() }
                .foregroundColor(AppTheme.textSecondary)
        }
    }

    // MARK: - Actions

    private func remove(_ component: MealComponent) {
        components.removeAll { $0.id == component.id }
    }

    /// Hydrate the form from `existingMeal` on first appearance only. Guarded
    /// against double-loading if the view re-appears (e.g. after dismissing a
    /// sheet) so user edits aren't clobbered.
    private func loadExistingMealIfNeeded() {
        guard components.isEmpty, let meal = existingMeal else { return }
        mealName = meal.name
        components = meal.ingredients.map(MealComponent.init(ingredient:))
    }

    private func saveMeal() {
        guard canSave else { return }
        let resolvedName = mealName.isEmpty ? "Custom Meal" : mealName

        var newMeal = FoodItem(
            name: resolvedName,
            weightInGrams: Int(totals.weightInGrams.rounded()),
            servings: 1,
            calories: totals.calories,
            protein: totals.protein,
            carbs: totals.carbs,
            fats: totals.fats,
            servingUnit: .grams,
            isFavorite: existingMeal?.isFavorite ?? false,
            isMeal: true,
            ingredients: components.map { $0.toIngredient() }
        )

        // When editing, preserve the original meal's id so the dictionary
        // updates in place rather than appending a duplicate entry.
        if let existingId = existingMeal?.id {
            newMeal.id = existingId
        }

        print("✅ BUILT MEAL:", newMeal.name,
              "isMeal:", newMeal.isMeal,
              "id:", newMeal.id,
              "ingredients:", newMeal.ingredients.count)

        if let onSave = onSave {
            onSave(newMeal)
        } else {
            foodModel.add(newMeal)
        }
        dismiss()
    }
}

// MARK: - Component row

/// One ingredient card in the components list.
private struct ComponentRow: View {
    let component: MealComponent
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(component.food.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)

                Text(component.quantityDescription)
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textSecondary)

                HStack(spacing: 6) {
                    MacroPill(value: "\(Int(component.calories.rounded()))",
                              label: "cal",
                              color: AppTheme.calorieColor)
                    MacroPill(value: String(format: "%.0f", component.protein),
                              label: "P",
                              color: AppTheme.proteinColor)
                    MacroPill(value: String(format: "%.0f", component.carbs),
                              label: "C",
                              color: AppTheme.carbColor)
                    MacroPill(value: String(format: "%.0f", component.fats),
                              label: "F",
                              color: AppTheme.fatColor)
                }
            }

            Spacer()

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .modifier(CardBackground(cornerRadius: 14))
    }
}

// MARK: - Reusable card chrome

/// The standard rounded-card background used across the screen. Centralizing
/// it keeps stroke width, fill, and corner radius consistent.
private struct CardBackground: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content.background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(AppTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(AppTheme.border, lineWidth: 1)
                )
        )
    }
}

// MARK: - Food picker sheet

/// Self-contained "pick a food → choose mode → enter quantity" flow.
///
/// All transient selection state (which food, which mode, quantity in flight,
/// which sub-presentation is up) lives here so the parent only sees the
/// finished selection through the `onAdd` callback. SwiftUI tears this view
/// down when the sheet dismisses, which automatically resets everything for
/// the next presentation.
private struct FoodPickerSheet: View {
    @ObservedObject var foodModel: FoodModel
    let onAdd: (FoodItem, Double, MeasurementMode) -> Void

    // Bindings required by DictionaryView / GramsOrServingsInput.
    @State private var selectedFood: FoodItem?
    @State private var selectedFoodID: UUID?
    @State private var selectedMode: MeasurementMode?
    @State private var pendingQuantity: Double?

    // Sub-presentation flags.
    @State private var isQuantityInputPresented: Bool = false
    @State private var isModeDialogPresented: Bool = false

    var body: some View {
        ZStack {
            DictionaryView(
                selectedFood: $selectedFood,
                showGramsInput: $isQuantityInputPresented,
                selectedFoodID: $selectedFoodID,
                selectedMeasurementMode: $selectedMode,
                foodModel: foodModel,
                onFoodSelected: handleFoodTapped,
                readOnly: true
            )

            if isQuantityInputPresented,
               let food = selectedFood,
               let mode = selectedMode {
                GramsOrServingsInput(
                    food: food,
                    mode: mode,
                    gramsOrServings: $pendingQuantity,
                    showGramsInput: $isQuantityInputPresented,
                    updateMacros: { _, _, _, _ in
                        onAdd(food, pendingQuantity ?? 0, mode)
                    }
                )
            }
        }
        .onChange(of: isQuantityInputPresented) { isShowing in
            // Defensive: if the quantity input is dismissed without producing
            // a value, clear the partial selection so a stray render of the
            // overlay can't reappear with stale data.
            if !isShowing { resetSelection() }
        }
        .confirmationDialog(
            "Track by",
            isPresented: $isModeDialogPresented,
            titleVisibility: .visible
        ) {
            if let food = selectedFood {
                Button(weightLabel(for: food)) { beginQuantityInput(.weight) }
                Button("Servings")             { beginQuantityInput(.serving) }
                Button("Cancel", role: .cancel) { resetSelection() }
            }
        }
    }

    // MARK: - Flow steps

    private func handleFoodTapped(_ food: FoodItem) {
        selectedFood = food
        selectedFoodID = food.id
        selectedMode = nil
        isQuantityInputPresented = false
        isModeDialogPresented = true
    }

    private func beginQuantityInput(_ mode: MeasurementMode) {
        selectedMode = mode
        isQuantityInputPresented = true
    }

    private func resetSelection() {
        selectedFood = nil
        selectedFoodID = nil
        selectedMode = nil
    }

    /// "Volume" reads better than "Weight" for liquids; otherwise stick with
    /// "Weight" for the food's grams-based portion.
    private func weightLabel(for food: FoodItem) -> String {
        food.servingUnit == .milliliters ? "Volume" : "Weight"
    }
}
