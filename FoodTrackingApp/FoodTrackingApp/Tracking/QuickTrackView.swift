import SwiftUI

struct QuickMacroTrackView: View {
    @Environment(\.presentationMode) var presentationMode

    @State private var name = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fats = ""

    /// Non-nil when editing an already-logged quick entry instead of creating one.
    private let editingEntry: LoggedFoodEntry?
    var onLog: (FoodItem) -> Void

    init(editing entry: LoggedFoodEntry? = nil, onLog: @escaping (FoodItem) -> Void) {
        self.editingEntry = entry
        self.onLog = onLog
        if let entry {
            // Prefill with the entry's current (scaled) values.
            _name = State(initialValue: entry.food.name)
            _calories = State(initialValue: "\(entry.scaledCalories)")
            _protein = State(initialValue: Self.format(entry.scaledProtein))
            _carbs = State(initialValue: Self.format(entry.scaledCarbs))
            _fats = State(initialValue: Self.format(entry.scaledFats))
        }
    }

    private var isEditing: Bool { editingEntry != nil }

    /// "12" for whole numbers, "12.5" otherwise.
    private static func format(_ value: Double) -> String {
        let rounded = (value * 10).rounded() / 10
        return rounded == rounded.rounded() ? String(Int(rounded)) : String(format: "%.1f", rounded)
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 40, weight: .light))
                                .foregroundColor(AppTheme.textPrimary)
                            
                            Text(isEditing ? "Edit Quick Entry" : "Quick Track")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary)
                            
                            Text(isEditing ? "Update this entry's name and macros" : "Log macros without saving to dictionary")
                                .font(.system(size: 14))
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 8)
                        
                        // Food Name
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Food Name (optional)")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(AppTheme.textSecondary)
                            ThemedTextField(placeholder: "e.g., Lunch", text: $name)
                        }
                        
                        // Nutrition
                        VStack(spacing: 0) {
                            // Calories
                            HStack {
                                HStack(spacing: 12) {
                                    Circle()
                                        .fill(AppTheme.calorieColor)
                                        .frame(width: 10, height: 10)
                                    Text("Calories")
                                        .font(.system(size: 16))
                                        .foregroundColor(AppTheme.textPrimary)
                                }
                                Spacer()
                                TextField("0", text: $calories)
                                    .keyboardType(.numberPad)
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(AppTheme.textPrimary)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 100)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                            
                            Divider().background(AppTheme.divider).padding(.horizontal, 16)
                            
                            // Protein
                            HStack {
                                HStack(spacing: 12) {
                                    Circle()
                                        .fill(AppTheme.proteinColor)
                                        .frame(width: 10, height: 10)
                                    Text("Protein (g)")
                                        .font(.system(size: 16))
                                        .foregroundColor(AppTheme.textPrimary)
                                }
                                Spacer()
                                TextField("0", text: $protein)
                                    .keyboardType(.decimalPad)
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(AppTheme.textPrimary)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 100)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                            
                            Divider().background(AppTheme.divider).padding(.horizontal, 16)
                            
                            // Carbs
                            HStack {
                                HStack(spacing: 12) {
                                    Circle()
                                        .fill(AppTheme.carbColor)
                                        .frame(width: 10, height: 10)
                                    Text("Carbs (g)")
                                        .font(.system(size: 16))
                                        .foregroundColor(AppTheme.textPrimary)
                                }
                                Spacer()
                                TextField("0", text: $carbs)
                                    .keyboardType(.decimalPad)
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(AppTheme.textPrimary)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 100)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                            
                            Divider().background(AppTheme.divider).padding(.horizontal, 16)
                            
                            // Fats
                            HStack {
                                HStack(spacing: 12) {
                                    Circle()
                                        .fill(AppTheme.fatColor)
                                        .frame(width: 10, height: 10)
                                    Text("Fats (g)")
                                        .font(.system(size: 16))
                                        .foregroundColor(AppTheme.textPrimary)
                                }
                                Spacer()
                                TextField("0", text: $fats)
                                    .keyboardType(.decimalPad)
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(AppTheme.textPrimary)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 100)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(AppTheme.cardBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(AppTheme.border, lineWidth: 1)
                                )
                        )
                        
                        // Log Button
                        Button {
                            guard let cal = Int(calories),
                                  let prot = Double(protein),
                                  let carb = Double(carbs),
                                  let fat = Double(fats) else {
                                return
                            }

                            let quickFood = FoodItem(
                                name: name.isEmpty ? "Quick Entry" : name,
                                weightInGrams: 0,
                                servings: 1,
                                calories: cal,
                                protein: prot,
                                carbs: carb,
                                fats: fat,
                                servingUnit: .grams
                            )

                            onLog(quickFood)
                            presentationMode.wrappedValue.dismiss()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: isEditing ? "checkmark.circle.fill" : "plus.circle.fill")
                                    .font(.system(size: 18))
                                Text(isEditing ? "Save Changes" : "Log Macros")
                            }
                        }
                        .buttonStyle(SleekButtonStyle())
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle(isEditing ? "Edit Quick Entry" : "Quick Track")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(AppTheme.textSecondary)
                }
            }
        }
    }
}
