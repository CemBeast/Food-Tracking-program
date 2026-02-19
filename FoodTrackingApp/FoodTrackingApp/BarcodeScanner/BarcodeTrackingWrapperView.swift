//
//  BarcodeTrackingWrapperView.swift
//  FoodTrackingApp
//
//  Created by Cem Beyenal on 5/20/25.
//
import SwiftUI

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
                Color.black.opacity(0.85)
                    .ignoresSafeArea()
                    .transition(.opacity)
                
                EditFoodItemView(
                    foodItem: food,
                    isAdding: true,
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
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeOut(duration: 0.25), value: showEdit)
    }
}
