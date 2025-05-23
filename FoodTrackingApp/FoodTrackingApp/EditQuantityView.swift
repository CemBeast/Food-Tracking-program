//
//  EditQuantityView.swift
//  FoodTrackingApp
//
//  Created by Cem Beyenal on 5/22/25.
//
import SwiftUI

struct EditQuantityView: View {
    @Environment(\.dismiss) private var dismiss
    let entry: LoggedFoodEntry
    var onSave: (Int) -> Void
    @State private var quantityInput: String

    init(entry: LoggedFoodEntry, onSave: @escaping (Int) -> Void) {
        self.entry = entry
        self.onSave = onSave
        self._quantityInput = State(initialValue: String(entry.quantity))
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Edit Quantity")
                .font(.title2)
                .bold()

            Text("Current: \(entry.quantity) \(entry.mode == .serving ? "serving(s)" : entry.servingUnit.rawValue)")

            TextField("New quantity", text: $quantityInput)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)

            Button("Save") {
                if let newQty = Int(quantityInput), newQty > 0 {
                    onSave(newQty)
                    dismiss()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
        }
        .padding()
    }
}
