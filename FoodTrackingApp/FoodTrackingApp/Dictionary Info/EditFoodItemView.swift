//
//  EditFoodItemView.swift
//  FoodTrackingApp
//
//  Created by Cem Beyenal on 5/20/25.
//
import SwiftUI

let intFormatter: NumberFormatter = {
    let f = NumberFormatter()
    f.numberStyle = .none
    return f
}()

private let decimalFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = 1
    formatter.allowsFloats = true
    return formatter
}()

// For selecting entire int values at once
struct SelectableTextFieldInt: UIViewRepresentable {
    @Binding var value: Int
    var formatter: NumberFormatter
    var keyboardType: UIKeyboardType

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: SelectableTextFieldInt
        init(_ parent: SelectableTextFieldInt) { self.parent = parent }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            DispatchQueue.main.async { textField.selectAll(nil) }
        }

        @objc func textFieldDidChange(_ textField: UITextField) {
            if let text = textField.text,
               let number = parent.formatter.number(from: text) {
                parent.value = number.intValue
            }
        }
    }

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.keyboardType = keyboardType
        textField.textAlignment = .right
        textField.autocorrectionType = .no
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textFieldDidChange(_:)), for: .editingChanged)
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = formatter.string(from: NSNumber(value: value))
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}

// For selecting entire double values at once
struct SelectableTextFieldDouble: UIViewRepresentable {
    @Binding var value: Double
    var formatter: NumberFormatter
    var keyboardType: UIKeyboardType

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: SelectableTextFieldDouble
        init(_ parent: SelectableTextFieldDouble) { self.parent = parent }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            DispatchQueue.main.async { textField.selectAll(nil) }
        }

        @objc func textFieldDidChange(_ textField: UITextField) {
            if let text = textField.text,
               let number = parent.formatter.number(from: text) {
                parent.value = number.doubleValue
            }
        }
    }

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.keyboardType = keyboardType
        textField.textAlignment = .right
        textField.autocorrectionType = .no
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textFieldDidChange(_:)), for: .editingChanged)
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = formatter.string(from: NSNumber(value: value))
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}

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
                            SelectableTextFieldInt(value: $foodItem.weightInGrams, formatter: intFormatter, keyboardType: .numberPad)
                                .frame(height: 30)
                        }
                    }

                    Group {
                        HStack {
                            Text("Calories")
                            Spacer()
                            SelectableTextFieldInt(value: $foodItem.calories, formatter: intFormatter, keyboardType: .numberPad)
                                .frame(height: 30)
                        }
                        HStack {
                            Text("Protein (g)")
                            Spacer()
                            SelectableTextFieldDouble(value: $foodItem.protein, formatter: decimalFormatter, keyboardType: .decimalPad)
                                .frame(height: 30)
                        }
                        HStack {
                            Text("Carbs (g)")
                            Spacer()
                            SelectableTextFieldDouble(value: $foodItem.carbs, formatter: decimalFormatter, keyboardType: .decimalPad)
                                .frame(height: 30)
                        }
                        HStack {
                            Text("Fats (g)")
                            Spacer()
                            SelectableTextFieldDouble(value: $foodItem.fats, formatter: decimalFormatter, keyboardType: .decimalPad)
                                .frame(height: 30)
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
