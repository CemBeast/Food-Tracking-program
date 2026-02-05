//
//  MacroGoalWizardView.swift
//  FoodTrackingApp
//
//  Created by Cem Beyenal on 6/6/25.
//
import SwiftUI

struct MacroGoalWizardView: View {
    @Environment(\.dismiss) var dismiss

    @Binding var calorieGoal: Int
    @Binding var proteinGoal: Double
    @Binding var carbGoal: Double
    @Binding var fatGoal: Double

    @State private var age: Int = 25
    @State private var heightFeet: Int = 5
    @State private var heightInches: Int = 8
    @State private var weightLbs: Double = 154
    @State private var sex: String = "Male"
    @State private var activityLevel: String = "Moderate"
    @State private var personalGoal: String = "Maintain Weight"

    let sexes = ["Male", "Female"]
    let activityOptions = ["Sedentary", "Light", "Moderate", "Active", "Very Active"]
    let goals = [
        "Very Significant Weight Gain (2 lb/week)",
        "Significant Weight Gain (1.5 lb/week)",
        "Moderate Weight Gain (1 lb/week)",
        "Mild Weight Gain (0.5 lb/week)",
        "Maintain Weight",
        "Mild Weight Loss (0.5 lb/week)",
        "Moderate Weight Loss (1 lb/week)",
        "Significant Weight Loss (1.5 lb/week)",
        "Very Significant Weight Loss (2 lb/week)"
    ]

    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 40, weight: .light))
                                .foregroundColor(AppTheme.textPrimary)
                            
                            Text("Calculate Your Macros")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary)
                            
                            Text("We'll calculate your ideal daily targets")
                                .font(.system(size: 14))
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 8)
                        
                        // Personal Info Section
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Personal Info")
                            
                            VStack(spacing: 0) {
                                // Sex
                                HStack {
                                    Text("Sex")
                                        .font(.system(size: 15))
                                        .foregroundColor(AppTheme.textPrimary)
                                    Spacer()
                                    HStack(spacing: 8) {
                                        ForEach(sexes, id: \.self) { option in
                                            Button {
                                                sex = option
                                            } label: {
                                                Text(option)
                                                    .font(.system(size: 14, weight: .medium))
                                                    .foregroundColor(sex == option ? .black : AppTheme.textSecondary)
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 8)
                                                    .background(
                                                        RoundedRectangle(cornerRadius: 8)
                                                            .fill(sex == option ? Color.white : Color.clear)
                                                    )
                                            }
                                        }
                                    }
                                    .padding(4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.white.opacity(0.06))
                                    )
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                
                                Divider().background(AppTheme.divider).padding(.horizontal, 16)
                                
                                // Age
                                HStack {
                                    Text("Age")
                                        .font(.system(size: 15))
                                        .foregroundColor(AppTheme.textPrimary)
                                    Spacer()
                                    HStack(spacing: 16) {
                                        Button {
                                            if age > 10 { age -= 1 }
                                        } label: {
                                            Image(systemName: "minus.circle.fill")
                                                .font(.system(size: 24))
                                                .foregroundColor(AppTheme.textSecondary)
                                        }
                                        Text("\(age)")
                                            .font(.system(size: 18, weight: .bold, design: .rounded))
                                            .foregroundColor(AppTheme.textPrimary)
                                            .frame(minWidth: 40)
                                        Button {
                                            if age < 100 { age += 1 }
                                        } label: {
                                            Image(systemName: "plus.circle.fill")
                                                .font(.system(size: 24))
                                                .foregroundColor(AppTheme.textPrimary)
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                
                                Divider().background(AppTheme.divider).padding(.horizontal, 16)
                                
                                // Height
                                HStack {
                                    Text("Height")
                                        .font(.system(size: 15))
                                        .foregroundColor(AppTheme.textPrimary)
                                    Spacer()
                                    HStack(spacing: 8) {
                                        Button {
                                            if heightInches > 0 {
                                                heightInches -= 1
                                            } else if heightFeet > 1 {
                                                heightInches = 11
                                                heightFeet -= 1
                                            }
                                        } label: {
                                            Image(systemName: "minus.circle.fill")
                                                .font(.system(size: 24))
                                                .foregroundColor(AppTheme.textSecondary)
                                        }
                                        Text("\(heightFeet)'\(heightInches)\"")
                                            .font(.system(size: 18, weight: .bold, design: .rounded))
                                            .foregroundColor(AppTheme.textPrimary)
                                            .frame(minWidth: 60)
                                        Button {
                                            if heightInches < 11 {
                                                heightInches += 1
                                            } else {
                                                heightInches = 0
                                                heightFeet += 1
                                            }
                                        } label: {
                                            Image(systemName: "plus.circle.fill")
                                                .font(.system(size: 24))
                                                .foregroundColor(AppTheme.textPrimary)
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                
                                Divider().background(AppTheme.divider).padding(.horizontal, 16)
                                
                                // Weight
                                HStack {
                                    Text("Weight")
                                        .font(.system(size: 15))
                                        .foregroundColor(AppTheme.textPrimary)
                                    Spacer()
                                    HStack(spacing: 8) {
                                        Button {
                                            if weightLbs > 66 { weightLbs -= 1 }
                                        } label: {
                                            Image(systemName: "minus.circle.fill")
                                                .font(.system(size: 24))
                                                .foregroundColor(AppTheme.textSecondary)
                                        }
                                        Text("\(Int(weightLbs)) lbs")
                                            .font(.system(size: 18, weight: .bold, design: .rounded))
                                            .foregroundColor(AppTheme.textPrimary)
                                            .frame(minWidth: 80)
                                        Button {
                                            if weightLbs < 400 { weightLbs += 1 }
                                        } label: {
                                            Image(systemName: "plus.circle.fill")
                                                .font(.system(size: 24))
                                                .foregroundColor(AppTheme.textPrimary)
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(AppTheme.cardBackground)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(AppTheme.border, lineWidth: 1)
                                    )
                            )
                        }
                        
                        // Activity Level Section
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Activity Level")
                            
                            VStack(spacing: 8) {
                                ForEach(activityOptions, id: \.self) { option in
                                    Button {
                                        activityLevel = option
                                    } label: {
                                        HStack {
                                            Text(option)
                                                .font(.system(size: 15, weight: activityLevel == option ? .semibold : .regular))
                                                .foregroundColor(activityLevel == option ? .black : AppTheme.textPrimary)
                                            Spacer()
                                            if activityLevel == option {
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 14, weight: .bold))
                                                    .foregroundColor(.black)
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 14)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(activityLevel == option ? Color.white : AppTheme.cardBackground)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(activityLevel == option ? Color.clear : AppTheme.border, lineWidth: 1)
                                                )
                                        )
                                    }
                                }
                            }
                        }
                        
                        // Goal Section
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Your Goal")
                            
                            Menu {
                                ForEach(goals, id: \.self) { goal in
                                    Button {
                                        personalGoal = goal
                                    } label: {
                                        Text(goal)
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(personalGoal)
                                        .font(.system(size: 15))
                                        .foregroundColor(AppTheme.textPrimary)
                                    Spacer()
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.system(size: 12))
                                        .foregroundColor(AppTheme.textSecondary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(AppTheme.cardBackground)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(AppTheme.border, lineWidth: 1)
                                        )
                                )
                            }
                        }
                        
                        // Calculate Button
                        Button {
                            calculateMacros()
                            dismiss()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 18))
                                Text("Calculate My Macros")
                            }
                        }
                        .buttonStyle(SleekButtonStyle())
                        .padding(.top, 8)
                        .padding(.bottom, 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Macro Calculator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.textSecondary)
                }
            }
        }
    }

    func calculateMacros() {
        let height = Double(heightFeet * 12 + heightInches) * 2.54
        let weight = weightLbs * 0.453592
        let bmr: Double = {
            if sex == "Male" {
                return (10 * weight) + (6.25 * height) - (5 * Double(age)) + 5
            } else {
                return (10 * weight) + (6.25 * height) - (5 * Double(age)) - 161
            }
        }()

        let activityMultiplier: Double = {
            switch activityLevel {
            case "Sedentary": return 1.2
            case "Light": return 1.375
            case "Moderate": return 1.55
            case "Active": return 1.725
            case "Very Active": return 1.9
            default: return 1.55
            }
        }()
        
        let goalCalorieAdjustment: Int = {
            switch personalGoal {
            case "Very Significant Weight Gain (2 lb/week)": return 1000
            case "Significant Weight Gain (1.5 lb/week)": return 750
            case "Moderate Weight Gain (1 lb/week)": return 500
            case "Mild Weight Gain (0.5 lb/week)": return 250
            case "Mild Weight Loss (0.5 lb/week)": return -250
            case "Moderate Weight Loss (1 lb/week)": return -500
            case "Significant Weight Loss (1.5 lb/week)": return -750
            case "Very Significant Weight Loss (2 lb/week)": return -1000
            default: return 0
            }
        }()

        let totalCalories = Int(bmr * activityMultiplier) + goalCalorieAdjustment
        calorieGoal = totalCalories

        proteinGoal = Double(weight) * 2.0
        fatGoal = Double(totalCalories) * 0.25 / 9
        let proteinCals = proteinGoal * 4
        let fatCals = fatGoal * 9
        let remainingCals = Double(totalCalories) - proteinCals - fatCals
        carbGoal = remainingCals / 4
    }
}
