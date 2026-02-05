//
//  EditGoalsView.swift
//  FoodTrackingApp
//
//  Created by Cem Beyenal on 5/27/25.
//
import SwiftUI

struct EditGoalsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var calorieGoal: Int
    @Binding var proteinGoal: Double
    @Binding var carbGoal: Double
    @Binding var fatGoal: Double
    
    @State private var calorieText: String = ""
    @State private var proteinText: String = ""
    @State private var carbText: String = ""
    @State private var fatText: String = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "target")
                                .font(.system(size: 40, weight: .light))
                                .foregroundColor(AppTheme.textPrimary)
                            
                            Text("Set Your Daily Goals")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary)
                            
                            Text("Adjust your daily macro targets")
                                .font(.system(size: 14))
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 8)
                        
                        // Macro Goals Card
                        VStack(spacing: 0) {
                            // Calories
                            GoalRow(
                                label: "Calories",
                                value: $calorieText,
                                color: AppTheme.calorieColor,
                                keyboardType: .numberPad
                            )
                            
                            Divider().background(AppTheme.divider).padding(.horizontal, 16)
                            
                            // Protein
                            GoalRow(
                                label: "Protein (g)",
                                value: $proteinText,
                                color: AppTheme.proteinColor,
                                keyboardType: .decimalPad
                            )
                            
                            Divider().background(AppTheme.divider).padding(.horizontal, 16)
                            
                            // Carbs
                            GoalRow(
                                label: "Carbs (g)",
                                value: $carbText,
                                color: AppTheme.carbColor,
                                keyboardType: .decimalPad
                            )
                            
                            Divider().background(AppTheme.divider).padding(.horizontal, 16)
                            
                            // Fats
                            GoalRow(
                                label: "Fats (g)",
                                value: $fatText,
                                color: AppTheme.fatColor,
                                keyboardType: .decimalPad
                            )
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(AppTheme.cardBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(AppTheme.border, lineWidth: 1)
                                )
                        )
                        
                        // Summary
                        VStack(spacing: 8) {
                            Text("Daily Summary")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(AppTheme.textTertiary)
                                .tracking(1)
                            
                            HStack(spacing: 16) {
                                SummaryPill(value: calorieText.isEmpty ? "0" : calorieText, label: "cal", color: AppTheme.calorieColor)
                                SummaryPill(value: proteinText.isEmpty ? "0" : proteinText, label: "P", color: AppTheme.proteinColor)
                                SummaryPill(value: carbText.isEmpty ? "0" : carbText, label: "C", color: AppTheme.carbColor)
                                SummaryPill(value: fatText.isEmpty ? "0" : fatText, label: "F", color: AppTheme.fatColor)
                            }
                        }
                        .padding(.top, 8)
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Edit Goals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        saveGoals()
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.textSecondary)
                }
            }
            .onAppear {
                calorieText = String(calorieGoal)
                proteinText = String(format: "%.0f", proteinGoal)
                carbText = String(format: "%.0f", carbGoal)
                fatText = String(format: "%.0f", fatGoal)
            }
        }
    }
    
    private func saveGoals() {
        if let cal = Int(calorieText) { calorieGoal = cal }
        if let prot = Double(proteinText) { proteinGoal = prot }
        if let carb = Double(carbText) { carbGoal = carb }
        if let fat = Double(fatText) { fatGoal = fat }
    }
}

// MARK: - Goal Row
struct GoalRow: View {
    let label: String
    @Binding var value: String
    let color: Color
    var keyboardType: UIKeyboardType = .numberPad
    
    var body: some View {
        HStack {
            HStack(spacing: 12) {
                Circle()
                    .fill(color)
                    .frame(width: 10, height: 10)
                
                Text(label)
                    .font(.system(size: 16))
                    .foregroundColor(AppTheme.textPrimary)
            }
            
            Spacer()
            
            TextField("0", text: $value)
                .keyboardType(keyboardType)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.textPrimary)
                .multilineTextAlignment(.trailing)
                .frame(width: 100)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }
}

// MARK: - Summary Pill
struct SummaryPill: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(color.opacity(0.7))
        }
        .frame(minWidth: 50)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.1))
        )
    }
}
