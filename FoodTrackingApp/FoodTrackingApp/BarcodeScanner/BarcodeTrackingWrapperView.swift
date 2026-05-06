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
    @State private var lookupError: BarcodeLookupError? = nil

    let viewModel: FoodModel

    var body: some View {
        ZStack {
            ScannerTrackingViewWithOverlay(
                onScanned: { food in
                    scannedFood = food
                    showEdit = true
                },
                onError: { err in
                    lookupError = err
                }
            )

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
        .alert(
            "Couldn't add food",
            isPresented: Binding(
                get: { lookupError != nil },
                set: { if !$0 { lookupError = nil } }
            ),
            presenting: lookupError
        ) { _ in
            Button("Try again", role: .cancel) {
                lookupError = nil
            }
            Button("Cancel", role: .destructive) {
                lookupError = nil
                dismiss()
            }
        } message: { err in
            Text(err.message)
        }
    }
}
