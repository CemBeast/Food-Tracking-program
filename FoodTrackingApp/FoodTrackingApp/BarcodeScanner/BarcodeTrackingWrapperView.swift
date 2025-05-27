//
//  BarcodeTrackingWrapperView.swift
//  FoodTrackingApp
//
//  Created by Cem Beyenal on 5/20/25.
//
import SwiftUI

//struct BarcodeTrackingWrapperView: View {
//    @Environment(\.dismiss) private var dismiss
//    @State private var scannedFood: FoodItem? = nil
//    @State private var showEdit = false
//    @State private var showInputPrompt = false
//
//    let viewModel: MacroTrackerViewModel
//
//    var body: some View {
//        ZStack {
//            if scannedFood == nil {
//                ScannerViewForTracking(onScanned: { food in
//                    scannedFood = food
//                    showEdit = true
//                })
//            }
//
//            if let food = scannedFood {
//                if showEdit {
//                    EditFoodItemView(
//                        foodItem: food,
//                        onSave: { updated in
//                            scannedFood = updated
//                            showEdit = false
//                            showInputPrompt = true
//                        },
//                        onCancel: {
//                            dismiss()
//                        }
//                    )
//                }
//
//                if showInputPrompt {
//                    GramsOrServingsInput(
//                        food: food,
//                        mode: food.servings > 0 ? .serving : .weight,
//                        gramsOrServings: .constant(nil),
//                        showGramsInput: .constant(true),
//                        updateMacros: { cals, fats, prot, carbs in
//                            viewModel.calories += Int(cals)
//                            viewModel.fats += fats
//                            viewModel.protein += prot
//                            viewModel.carbs += carbs
//                            dismiss()
//                        }
//                    )
//                }
//            }
//        }
//    }
//}

struct BarcodeTrackingWrapperView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var scannedFood: FoodItem? = nil
    @State private var showEdit = false

    let viewModel: FoodModel

    var body: some View {
        ZStack {
            ScannerTrackingViewWithOverlay { food in
                scannedFood = food
                showEdit = true
            }

            if let food = scannedFood, showEdit {
                EditFoodItemView(
                    foodItem: food,
                    onSave: { updated in
                        viewModel.add(updated)
                        showEdit = false
                        dismiss()
                    },
                    onCancel: {
                        showEdit = false
                        dismiss()
                    }
                )
                .background(Color.black.opacity(0.4).ignoresSafeArea())
            }
        }
    }
}
