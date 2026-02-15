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
        textField.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        textField.textColor = UIColor(AppTheme.textPrimary)
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
        textField.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        textField.textColor = UIColor(AppTheme.textPrimary)
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
    @State var isAdding: Bool = false
    var onSave: (FoodItem) -> Void
    var onCancel: () -> Void

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.system(size: 40, weight: .light))
                            .foregroundColor(AppTheme.textPrimary)
                        
                        Text("Edit Food")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 8)
                    
                    // Food Info
                    VStack(spacing: 0) {
                        // Name
                        HStack {
                            Text("Name")
                                .font(.system(size: 15))
                                .foregroundColor(AppTheme.textSecondary)
                            Spacer()
                            TextField("Food name", text: $foodItem.name)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppTheme.textPrimary)
                                .multilineTextAlignment(.trailing)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        
                        Divider().background(AppTheme.divider).padding(.horizontal, 16)
                        
                        // Unit
                        HStack {
                            Text("Unit")
                                .font(.system(size: 15))
                                .foregroundColor(AppTheme.textSecondary)
                            Spacer()
                            HStack(spacing: 8) {
                                ForEach(ServingUnit.allCases) { unit in
                                    Button {
                                        foodItem.servingUnit = unit
                                    } label: {
                                        Text(unit.rawValue.uppercased())
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(foodItem.servingUnit == unit ? .black : AppTheme.textSecondary)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(foodItem.servingUnit == unit ? Color.white : Color.clear)
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
                        
                        // Servings
                        HStack {
                            Text("Servings")
                                .font(.system(size: 15))
                                .foregroundColor(AppTheme.textSecondary)
                            Spacer()
                            HStack(spacing: 12) {
                                Button {
                                    if foodItem.servings > 1 { foodItem.servings -= 1 }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor(AppTheme.textSecondary)
                                }
                                Text("\(foodItem.servings)")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(AppTheme.textPrimary)
                                    .frame(minWidth: 30)
                                Button {
                                    foodItem.servings += 1
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor(AppTheme.textPrimary)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        
                        Divider().background(AppTheme.divider).padding(.horizontal, 16)
                        
                        // Weight/Volume
                        HStack {
                            Text(foodItem.servingUnit == .grams ? "Weight (g)" : "Volume (ml)")
                                .font(.system(size: 15))
                                .foregroundColor(AppTheme.textSecondary)
                            Spacer()
                            SelectableTextFieldInt(value: $foodItem.weightInGrams, formatter: intFormatter, keyboardType: .numberPad)
                                .frame(width: 80, height: 30)
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
                    
                    // Nutrition
                    VStack(spacing: 0) {
                        // Calories
                        HStack {
                            HStack(spacing: 10) {
                                Circle()
                                    .fill(AppTheme.calorieColor)
                                    .frame(width: 8, height: 8)
                                Text("Calories")
                                    .font(.system(size: 15))
                                    .foregroundColor(AppTheme.textPrimary)
                            }
                            Spacer()
                            SelectableTextFieldInt(value: $foodItem.calories, formatter: intFormatter, keyboardType: .numberPad)
                                .frame(width: 80, height: 30)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        
                        Divider().background(AppTheme.divider).padding(.horizontal, 16)
                        
                        // Protein
                        HStack {
                            HStack(spacing: 10) {
                                Circle()
                                    .fill(AppTheme.proteinColor)
                                    .frame(width: 8, height: 8)
                                Text("Protein (g)")
                                    .font(.system(size: 15))
                                    .foregroundColor(AppTheme.textPrimary)
                            }
                            Spacer()
                            SelectableTextFieldDouble(value: $foodItem.protein, formatter: decimalFormatter, keyboardType: .decimalPad)
                                .frame(width: 80, height: 30)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        
                        Divider().background(AppTheme.divider).padding(.horizontal, 16)
                        
                        // Carbs
                        HStack {
                            HStack(spacing: 10) {
                                Circle()
                                    .fill(AppTheme.carbColor)
                                    .frame(width: 8, height: 8)
                                Text("Carbs (g)")
                                    .font(.system(size: 15))
                                    .foregroundColor(AppTheme.textPrimary)
                            }
                            Spacer()
                            SelectableTextFieldDouble(value: $foodItem.carbs, formatter: decimalFormatter, keyboardType: .decimalPad)
                                .frame(width: 80, height: 30)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        
                        Divider().background(AppTheme.divider).padding(.horizontal, 16)
                        
                        // Fats
                        HStack {
                            HStack(spacing: 10) {
                                Circle()
                                    .fill(AppTheme.fatColor)
                                    .frame(width: 8, height: 8)
                                Text("Fats (g)")
                                    .font(.system(size: 15))
                                    .foregroundColor(AppTheme.textPrimary)
                            }
                            Spacer()
                            SelectableTextFieldDouble(value: $foodItem.fats, formatter: decimalFormatter, keyboardType: .decimalPad)
                                .frame(width: 80, height: 30)
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
                    
                    // Buttons
                    VStack(spacing: 12) {
                        Button {
                            onSave(foodItem)
                            dismiss()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 18))
                                if isAdding == false {
                                    Text("Save Changes")
                                } else {
                                    Text("Add Food")
                                }
                            }
                        }
                        .buttonStyle(SleekButtonStyle())
                        
                        Button {
                            onCancel()
                            dismiss()
                        } label: {
                            Text("Cancel")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                }
                .padding(.horizontal, 20)
            }
        }
        .presentationDragIndicator(.visible)
    }
}
