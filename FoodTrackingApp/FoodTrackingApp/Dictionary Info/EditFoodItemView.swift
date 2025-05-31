//
//  EditFoodItemView.swift
//  FoodTrackingApp
//
//  Created by Cem Beyenal on 5/20/25.
//
import SwiftUI

private let decimalFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = 1
    formatter.allowsFloats = true
    return formatter
}()

struct EditFoodItemView: View {
    @Environment(\.dismiss) private var dismiss
    @State var foodItem: FoodItem
    var onSave: (FoodItem) -> Void
    var onCancel: () -> Void

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 24) {
                Text("Edit Food Item")
                    .font(.title2)
                    .fontWeight(.semibold)

                VStack(spacing: 12) {
                    Group {
                        TextField("Name", text: $foodItem.name)
                        Stepper("Servings: \(foodItem.servings)", value: $foodItem.servings, in: 0...1000)
                        // Unit toggle
                        Picker("Unit", selection: $foodItem.servingUnit) {
                            ForEach(ServingUnit.allCases) { unit in
                                Text(unit.rawValue.uppercased()).tag(unit)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        HStack {
                            Text(foodItem.servingUnit == .grams ? "Weight" : "Volume")
                            Spacer()
                            TextField("0", value: $foodItem.weightInGrams, formatter: NumberFormatter())
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .disableAutocorrection(true)
                        }
                    }

                    Group {
                        HStack {
                            Text("Calories")
                            Spacer()
                            TextField("0", value: $foodItem.calories, formatter: NumberFormatter())
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .disableAutocorrection(true)
                        }
                        HStack {
                            Text("Protein (g)")
                            Spacer()
                            TextField("0", value: $foodItem.protein, formatter: decimalFormatter)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .disableAutocorrection(true)
                        }
                        HStack {
                            Text("Carbs (g)")
                            Spacer()
                            TextField("0", value: $foodItem.carbs, formatter: decimalFormatter)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .disableAutocorrection(true)
                        }
                        HStack {
                            Text("Fats (g)")
                            Spacer()
                            TextField("0", value: $foodItem.fats, formatter: decimalFormatter)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .disableAutocorrection(true)
                        }
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                .shadow(radius: 4)
                .frame(maxWidth: 320)

                HStack(spacing: 20) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                    .foregroundColor(.red)

                    Button("Save") {
                        onSave(foodItem)
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                }
            }
            .padding()
        }
    }
}
