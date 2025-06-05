//
//  AddFoodView.swift
//  FoodTrackingApp
//
//  Created by Cem Beyenal on 5/8/25.
//
import SwiftUI

struct AddFoodView: View {
    @Environment(\.presentationMode) var presentationMode

    var onAdd: (FoodItem) -> Void

    @State private var name = ""
    @State private var weightInGrams = ""
    @State private var servings = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fats = ""
    @State private var selectedUnit: ServingUnit = .grams

    var body: some View {
        ZStack {
            Color("PrimaryBackground").ignoresSafeArea()
            Form {
                Section(header: Text("Food Info")) {
                    TextField("Name", text: $name)
                    Picker("Measurement Unit", selection: $selectedUnit) {
                        ForEach(ServingUnit.allCases) { unit in
                            Text(unit.rawValue.uppercased()).tag(unit)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    TextField(selectedUnit == .grams ? "Weight (g)" : "Volume (ml)", text: $weightInGrams)
                        .keyboardType(.numberPad)
                    TextField("Servings", text: $servings)
                        .keyboardType(.numberPad)
                    TextField("Calories", text: $calories)
                        .keyboardType(.numberPad)
                    TextField("Protein (g)", text: $protein)
                        .keyboardType(.decimalPad)
                    TextField("Carbs (g)", text: $carbs)
                        .keyboardType(.decimalPad)
                    TextField("Fats (g)", text: $fats)
                        .keyboardType(.decimalPad)
                }
                
                Button("Add Food") {
                    guard let weight = Int(weightInGrams),
                          let servingsInt = Int(servings),
                          let cal = Int(calories),
                          let prot = Double(protein),
                          let carb = Double(carbs),
                          let fat = Double(fats) else {
                        // You could show an alert here
                        return
                    }
                    
                    let newFood = FoodItem(
                        name: name,
                        weightInGrams: weight,
                        servings: servingsInt,
                        calories: cal,
                        protein: prot,
                        carbs: carb,
                        fats: fat,
                        servingUnit: selectedUnit
                    )
                    onAdd(newFood)
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .navigationTitle("Add Food")
        }
    }
}
