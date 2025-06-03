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
                    
                   if entry.mode == .weight {
                       // e.g. "1.6 g"
                       Text(String(format: "%.0f %@", entry.quantity, entry.servingUnit.rawValue))
                           .font(.footnote)
                           .foregroundColor(.gray)
                   } else {
                       // Show quantity with exactly one decimal place
                       Text(String(format: "%.1f serving%@", entry.quantity, entry.quantity > 1 ? "s" : ""))
                           .font(.footnote)
                           .foregroundColor(.gray)
                   }
                    GeometryReader { geometry in
                        let itemWidth = geometry.size.width / 4

                        HStack(spacing: 0) {
                            macroColumn(icon: "flame.fill", label: "Calories", value: "\(entry.scaledCalories)", width: itemWidth, color: .red)
                            macroColumn(icon: "bolt.circle.fill", label: "Protein", value: String(format: "%.1fg", entry.scaledProtein), width: itemWidth, color: .yellow)
                            macroColumn(icon: "leaf.circle.fill", label: "Carbs", value: String(format: "%.1fg", entry.scaledCarbs), width: itemWidth, color: .green)
                            macroColumn(icon: "drop.circle.fill", label: "Fats", value: String(format: "%.1fg", entry.scaledFats), width: itemWidth, color: .purple)
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
                viewModel.updateFoodEntryQuantity(entry, newQuantity: Double(newQuantity))
                foodToEditQuantity = nil
            }
        }
        .navigationTitle("Today's Food Log")
    }

    @ViewBuilder
    func macroColumn(icon: String, label: String, value: String, width: CGFloat, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(color)
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
        .frame(width: width)
    }
}
