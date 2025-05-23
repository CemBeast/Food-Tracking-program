//
//  FoodLogView.swift
//  FoodTrackingApp
//
//  Created by Cem Beyenal on 5/21/25.
//
import SwiftUI

struct FoodLogView: View {
    @State private var foodToEditQuantity: LoggedFoodEntry?
    @ObservedObject var viewModel: MacroTrackerViewModel

    var body: some View {
        List {
            ForEach(viewModel.foodLog) { entry in
                VStack(alignment: .leading, spacing: 6) {
                    Text(entry.food.name)
                        .font(.headline)
                    
                    Text(entry.mode == .weight
                         ? "\(entry.quantity) \(entry.servingUnit.rawValue)"
                         : "\(entry.quantity) serving\(entry.quantity > 1 ? "s" : "")")
                    .font(.footnote)
                    .foregroundColor(.gray)

                    HStack {
                        Image(systemName: "flame.fill")
                        Text("Calories: \(entry.food.calories)")
                        Image(systemName: "bolt.circle.fill")
                        Text("Protein: \(String(format: "%.1f", entry.food.protein))g")
                        Image(systemName: "leaf.circle.fill")
                        Text("Carbs: \(String(format: "%.1f", entry.food.carbs))g")
                        Image(systemName: "drop.circle.fill")
                        Text("Fats: \(String(format: "%.1f", entry.food.fats))g")
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
                .padding(.vertical, 6)
                .onLongPressGesture {
                    foodToEditQuantity = entry
                }
            }
            .onDelete { indexSet in
                indexSet.forEach { index in
                    let entry = viewModel.foodLog[index]
                    viewModel.deleteFoodLogEntry(entry)
                }
            }
        }
        .sheet(item: $foodToEditQuantity) { entry in
            EditQuantityView(entry: entry) { newQuantity in
                viewModel.updateFoodEntryQuantity(entry, newQuantity: newQuantity)
                foodToEditQuantity = nil
            }
        }
        .navigationTitle("Today's Food Log")
    }

    @ViewBuilder
    func macroLabel(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
            Text("\(label): \(value)")
        }
    }
}
