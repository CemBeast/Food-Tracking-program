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
            Form {
                Section(header: Text("Personal Info")) {
                    Picker("Sex", selection: $sex) {
                        ForEach(sexes, id: \.self) { Text($0) }
                    }
                    Stepper("Age: \(age)", value: $age, in: 10...100)
                    Stepper("Height: \(heightFeet) ft \(heightInches) in", onIncrement: {
                        if heightInches < 11 {
                            heightInches += 1
                        } else {
                            heightInches = 0
                            heightFeet += 1
                        }
                    }, onDecrement: {
                        if heightInches > 0 {
                            heightInches -= 1
                        } else if heightFeet > 1 {
                            heightInches = 11
                            heightFeet -= 1
                        }
                    })

                    Stepper("Weight: \(weightLbs, specifier: "%.0f") lbs", value: $weightLbs, in: 66...400)
                }

                Section(header: Text("Activity Level")) {
                    Picker("Activity Level", selection: $activityLevel) {
                        ForEach(activityOptions, id: \.self) { Text($0) }
                    }
                }
                Section(header: Text("Your Goal")) {
                    Picker("Your Goal", selection: $personalGoal) {
                        ForEach(goals, id: \.self) { Text($0) }
                    }
                }

                Section {
                    Button("Calculate Macros") {
                        calculateMacros()
                        dismiss()
                    }
                    .font(.headline)
                }
            }
            .navigationTitle("Set Your Goals")
        }
    }

    func calculateMacros() {
        let height = Double(heightFeet * 12 + heightInches) * 2.54 // convert inches to cm
        let weight = weightLbs * 0.453592 // convert lbs to kg
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
            default: return 0 // Maintain Weight
            }
        }()

        let totalCalories = Int(bmr * activityMultiplier) + goalCalorieAdjustment
        calorieGoal = totalCalories

        proteinGoal = Double(weight) * 2.0 // grams per kg
        fatGoal = Double(totalCalories) * 0.25 / 9
        let proteinCals = proteinGoal * 4
        let fatCals = fatGoal * 9
        let remainingCals = Double(totalCalories) - proteinCals - fatCals
        carbGoal = remainingCals / 4
    }
}
