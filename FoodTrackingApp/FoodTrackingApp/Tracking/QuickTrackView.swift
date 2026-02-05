import SwiftUI

struct QuickMacroTrackView: View {
    @Environment(\.presentationMode) var presentationMode

    @State private var name = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fats = ""

    var onLog: (FoodItem) -> Void

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
                            
                            Text("Quick Track")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary)
                            
                            Text("Log macros without saving to dictionary")
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
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 18))
                                Text("Log Macros")
                            }
                        }
                        .buttonStyle(SleekButtonStyle())
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Quick Track")
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
