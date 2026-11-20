//
//  EditFoodItemView.swift
//  FoodTrackingApp
//
//  Created by Cem Beyenal on 5/20/25.
//
import SwiftUI
import UIKit

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder),
                   to: nil, from: nil, for: nil)
    }
}


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
        textField.font = UIFont.systemFont(ofSize: 18.scaled, weight: .bold)
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
        textField.font = UIFont.systemFont(ofSize: 18.scaled, weight: .bold)
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
    @State private var scaleWithWeight: Bool = false
    
    // Snapshot values used as the “per base weight” reference for scaling macros from weight
    @State private var baseWeight: Int = 0
    @State private var baseCalories: Int = 0
    @State private var baseProtein: Double = 0
    @State private var baseCarbs: Double = 0
    @State private var baseFats: Double = 0
    
    var onSave: (FoodItem) -> Void
    var onCancel: () -> Void

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView {
            VStack(spacing: 24.scaled) {
                // Header
                VStack(spacing: 8.scaled) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 40.scaled, weight: .light))
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Text("Edit Food")
                        .font(.system(size: 22.scaled, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                }
                .padding(.top, 16.scaled)
                // Food Info
                VStack(spacing: 0.scaled) {
                    // Name
                    HStack {
                        Text("Name")
                            .font(.system(size: 15.scaled))
                            .foregroundColor(AppTheme.textSecondary)
                        Spacer()
                        TextField("Food name", text: $foodItem.name)
                            .font(.system(size: 16.scaled, weight: .semibold))
                            .foregroundColor(AppTheme.textPrimary)
                            .multilineTextAlignment(.trailing)
                    }
                    .padding(.horizontal, 16.scaled)
                    .padding(.vertical, 14.scaled)
                    
                    Divider().background(AppTheme.divider).padding(.horizontal, 16.scaled)
                    
                    // Unit
                    HStack {
                        Text("Unit")
                            .font(.system(size: 15.scaled))
                            .foregroundColor(AppTheme.textSecondary)
                        Spacer()
                        HStack(spacing: 8.scaled) {
                            ForEach(ServingUnit.allCases) { unit in
                                Button {
                                    foodItem.servingUnit = unit
                                } label: {
                                    Text(unit.rawValue.uppercased())
                                        .font(.system(size: 13.scaled, weight: .semibold))
                                        .foregroundColor(foodItem.servingUnit == unit ? .black : AppTheme.textSecondary)
                                        .padding(.horizontal, 14.scaled)
                                        .padding(.vertical, 8.scaled)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8.scaled)
                                                .fill(foodItem.servingUnit == unit ? Color.white : Color.clear)
                                        )
                                }
                            }
                        }
                        .padding(4.scaled)
                        .background(
                            RoundedRectangle(cornerRadius: 10.scaled)
                                .fill(Color.white.opacity(0.06))
                        )
                    }
                    .padding(.horizontal, 16.scaled)
                    .padding(.vertical, 14.scaled)
                    
                    Divider().background(AppTheme.divider).padding(.horizontal, 16.scaled)
                    
                    // Servings
                    HStack {
                        Text("Servings")
                            .font(.system(size: 15.scaled))
                            .foregroundColor(AppTheme.textSecondary)
                        Spacer()
                        HStack(spacing: 12.scaled) {
                            Button {
                                if foodItem.servings > 1 { foodItem.servings -= 1 }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 22.scaled))
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                            Text("\(foodItem.servings)")
                                .font(.system(size: 18.scaled, weight: .bold, design: .rounded))
                                .foregroundColor(AppTheme.textPrimary)
                                .frame(minWidth: 30.scaled)
                            Button {
                                foodItem.servings += 1
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 22.scaled))
                                    .foregroundColor(AppTheme.textPrimary)
                            }
                        }
                    }
                    .padding(.horizontal, 16.scaled)
                    .padding(.vertical, 14.scaled)
                    
                    Divider().background(AppTheme.divider).padding(.horizontal, 16.scaled)
                    
                    // Weight/Volume
                    HStack {
                        Text(foodItem.servingUnit == .grams ? "Weight (g)" : "Volume (ml)")
                            .font(.system(size: 15.scaled))
                            .foregroundColor(AppTheme.textSecondary)
                        Spacer()
                        SelectableTextFieldInt(value: $foodItem.weightInGrams, formatter: intFormatter, keyboardType: .numberPad)
                            .frame(width: 80.scaled, height: 30.scaled)
                    }
                    .padding(.horizontal, 16.scaled)
                    .padding(.vertical, 14.scaled)
                }
                .background(
                    RoundedRectangle(cornerRadius: 16.scaled)
                        .fill(AppTheme.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16.scaled)
                                .stroke(AppTheme.border, lineWidth: 1)
                        )
                )
                
                HStack {
                    VStack(alignment: .leading, spacing: 4.scaled) {
                        Text("Scale macros with weight")
                            .font(.system(size: 15.scaled))
                            .foregroundColor(AppTheme.textPrimary)
                        Text("When on, macros update automatically when you change weight.")
                            .font(.system(size: 12.scaled))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $scaleWithWeight)
                        .labelsHidden()
                }
                .padding(.horizontal, 16.scaled)
                .onChange(of: scaleWithWeight) { isOn in
                    if isOn {
                        // freeze current macros as reference
                        captureBaseSnapshotFromCurrent()
                        applyScalingFromBase()
                    }
                }
                .onChange(of: foodItem.weightInGrams) { _ in
                    guard scaleWithWeight else {return}
                    applyScalingFromBase()
                }

                
                // Nutrition
                VStack(spacing: 0.scaled) {
                    // Calories
                    HStack {
                        HStack(spacing: 10.scaled) {
                            Circle()
                                .fill(AppTheme.calorieColor)
                                .frame(width: 8.scaled, height: 8.scaled)
                            Text("Calories")
                                .font(.system(size: 15.scaled))
                                .foregroundColor(AppTheme.textPrimary)
                        }
                        Spacer()
                        SelectableTextFieldInt(value: $foodItem.calories, formatter: intFormatter, keyboardType: .numberPad)
                            .frame(width: 80.scaled, height: 30.scaled)
                            .allowsHitTesting(!scaleWithWeight)
                            .opacity(scaleWithWeight ? 0.4 : 1 )
                    }
                    .padding(.horizontal, 16.scaled)
                    .padding(.vertical, 14.scaled)
                    
                    Divider().background(AppTheme.divider).padding(.horizontal, 16.scaled)
                    
                    // Protein
                    HStack {
                        HStack(spacing: 10.scaled) {
                            Circle()
                                .fill(AppTheme.proteinColor)
                                .frame(width: 8.scaled, height: 8.scaled)
                            Text("Protein (g)")
                                .font(.system(size: 15.scaled))
                                .foregroundColor(AppTheme.textPrimary)
                        }
                        Spacer()
                        SelectableTextFieldDouble(value: $foodItem.protein, formatter: decimalFormatter, keyboardType: .decimalPad)
                            .frame(width: 80.scaled, height: 30.scaled)
                            .allowsHitTesting(!scaleWithWeight)
                            .opacity(scaleWithWeight ? 0.4 : 1 )
                    }
                    .padding(.horizontal, 16.scaled)
                    .padding(.vertical, 14.scaled)
                    
                    Divider().background(AppTheme.divider).padding(.horizontal, 16.scaled)
                    
                    // Carbs
                    HStack {
                        HStack(spacing: 10.scaled) {
                            Circle()
                                .fill(AppTheme.carbColor)
                                .frame(width: 8.scaled, height: 8.scaled)
                            Text("Carbs (g)")
                                .font(.system(size: 15.scaled))
                                .foregroundColor(AppTheme.textPrimary)
                        }
                        Spacer()
                        SelectableTextFieldDouble(value: $foodItem.carbs, formatter: decimalFormatter, keyboardType: .decimalPad)
                            .frame(width: 80.scaled, height: 30.scaled)
                            .allowsHitTesting(!scaleWithWeight)
                            .opacity(scaleWithWeight ? 0.4 : 1 )
                    }
                    .padding(.horizontal, 16.scaled)
                    .padding(.vertical, 14.scaled)
                    
                    Divider().background(AppTheme.divider).padding(.horizontal, 16.scaled)
                    
                    // Fats
                    HStack {
                        HStack(spacing: 10.scaled) {
                            Circle()
                                .fill(AppTheme.fatColor)
                                .frame(width: 8.scaled, height: 8.scaled)
                            Text("Fats (g)")
                                .font(.system(size: 15.scaled))
                                .foregroundColor(AppTheme.textPrimary)
                        }
                        Spacer()
                        SelectableTextFieldDouble(value: $foodItem.fats, formatter: decimalFormatter, keyboardType: .decimalPad)
                            .frame(width: 80.scaled, height: 30.scaled)
                            .allowsHitTesting(!scaleWithWeight)
                            .opacity(scaleWithWeight ? 0.4 : 1 )
                    }
                    .padding(.horizontal, 16.scaled)
                    .padding(.vertical, 14.scaled)
                }
                .background(
                    RoundedRectangle(cornerRadius: 16.scaled)
                        .fill(AppTheme.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16.scaled)
                                .stroke(AppTheme.border, lineWidth: 1)
                        )
                )
                
                // Buttons
                VStack(spacing: 12.scaled) {
                    Button {
                        onSave(foodItem)
                        dismiss()
                    } label: {
                        HStack(spacing: 8.scaled) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18.scaled))
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
                            .font(.system(size: 15.scaled, weight: .medium))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
                .padding(.top, 8.scaled)
                .padding(.bottom, 32.scaled)
            }
            .padding(.horizontal, 20.scaled)
            }
        }
        .presentationDragIndicator(.visible)
    }
    
    private func captureBaseSnapshotFromCurrent() {
        baseWeight = foodItem.weightInGrams
        baseCalories = foodItem.calories
        baseProtein = foodItem.protein
        baseCarbs = foodItem.carbs
        baseFats = foodItem.fats
    }
    
    private func applyScalingFromBase() {
        let bw = baseWeight
        let nw = foodItem.weightInGrams
        // A 0 g base can't be scaled from (0/0 = NaN would crash Int(...)), so leave macros as-is.
        guard bw > 0 else { return }
        let factor = Double(nw) / Double(bw)

        // Clamp before Int(...) so an absurdly large typed weight can't overflow and crash.
        let scaledCalories = min((Double(baseCalories) * factor).rounded(), Double(Int32.max))
        foodItem.calories = Int(scaledCalories)
        foodItem.protein = baseProtein * factor
        foodItem.carbs = baseCarbs * factor
        foodItem.fats = baseFats * factor
    }
    
}

#Preview {
    EditFoodItemView(
        foodItem: FoodItem(
            name: "Grilled Chicken Breast",
            weightInGrams: 100,
            servings: 1,
            calories: 165,
            protein: 31.0,
            carbs: 0.0,
            fats: 3.6,
            servingUnit: .grams,
            isFavorite: true,
            isMeal: false,
            ingredients: []
        ),
        onSave: { _ in },
        onCancel: { }
    )
}
