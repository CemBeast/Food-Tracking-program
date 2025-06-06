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
    @State private var height: Double = 170 // cm
    @State private var weight: Double = 70 // kg
    @State private var sex: String = "Male"
    @State private var activityLevel: String = "Moderate"

    let sexes = ["Male", "Female"]
    let activityOptions = ["Sedentary", "Light", "Moderate", "Active", "Very Active"]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Info")) {
                    Picker("Sex", selection: $sex) {
                        ForEach(sexes, id: \.self) { Text($0) }
                    }
                    Stepper("Age: \(age)", value: $age, in: 10...100)
                    Stepper("Height: \(height, specifier: "%.0f") cm", value: $height, in: 100...230)
                    Stepper("Weight: \(weight, specifier: "%.0f") kg", value: $weight, in: 30...200)
                }

                Section(header: Text("Activity Level")) {
                    Picker("Activity Level", selection: $activityLevel) {
                        ForEach(activityOptions, id: \.self) { Text($0) }
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
        let bmr: Double = {
            if sex == "Male" {
                return 10 * weight + 6.25 * height - 5 * Double(age) + 5
            } else {
                return 10 * weight + 6.25 * height - 5 * Double(age) - 161
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

        let totalCalories = Int(bmr * activityMultiplier)
        calorieGoal = totalCalories

        proteinGoal = Double(weight) * 2.0 // grams per kg
        fatGoal = Double(totalCalories) * 0.25 / 9
        let proteinCals = proteinGoal * 4
        let fatCals = fatGoal * 9
        let remainingCals = Double(totalCalories) - proteinCals - fatCals
        carbGoal = remainingCals / 4
    }
}
