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

                    GeometryReader { geometry in
                        let itemWidth = geometry.size.width / 4

                        HStack(spacing: 0) {
                            macroColumn(icon: "flame.fill", label: "Calories", value: "\(entry.scaledCalories)", width: itemWidth)
                            macroColumn(icon: "bolt.circle.fill", label: "Protein", value: String(format: "%.1fg", entry.scaledProtein), width: itemWidth)
                            macroColumn(icon: "leaf.circle.fill", label: "Carbs", value: String(format: "%.1fg", entry.scaledCarbs), width: itemWidth)
                            macroColumn(icon: "drop.circle.fill", label: "Fats", value: String(format: "%.1fg", entry.scaledFats), width: itemWidth)
                        }
                    }
                    .frame(height: 50) // adjust as needed
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
    func macroColumn(icon: String, label: String, value: String, width: CGFloat) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.white)
            Text(label)
                .font(.caption2)
                .foregroundColor(.gray)
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
        .frame(width: width)
    }
}
