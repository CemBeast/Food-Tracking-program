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
    
    private let formatter: NumberFormatter = {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.maximumFractionDigits = 1
        return nf
    }()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Macro Goals")) {
                    TextField("Calories", value: $calorieGoal, formatter: formatter)
                        .keyboardType(.numberPad)
                    TextField("Protein (g)", value: $proteinGoal, formatter: formatter)
                        .keyboardType(.decimalPad)
                    TextField("Carbs (g)", value: $carbGoal, formatter: formatter)
                        .keyboardType(.decimalPad)
                    TextField("Fats (g)", value: $fatGoal, formatter: formatter)
                        .keyboardType(.decimalPad)
                }
            }
        }
        .navigationTitle("Edit Macro Goals")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done"){
                    dismiss()
                }
            }
        }
    }    
}
