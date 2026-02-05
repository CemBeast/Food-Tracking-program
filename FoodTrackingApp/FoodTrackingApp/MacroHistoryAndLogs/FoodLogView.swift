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
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            if viewModel.foodLog.isEmpty {
                // Empty State
                VStack(spacing: 16) {
                    Image(systemName: "fork.knife.circle")
                        .font(.system(size: 56, weight: .light))
                        .foregroundColor(AppTheme.textTertiary)
                    
                    Text("No Foods Logged")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Text("Start tracking your meals to see them here")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.textSecondary)
                }
            } else {
                List {
                    ForEach(viewModel.foodLog) { entry in
                        FoodLogEntryRow(entry: entry)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
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
                .listStyle(PlainListStyle())
                .scrollContentBackground(.hidden)
            }
        }
        .sheet(item: $foodToEditQuantity) { entry in
            EditQuantityView(entry: entry) { newQuantity in
                viewModel.updateFoodEntryQuantity(entry, newQuantity: Double(newQuantity))
                foodToEditQuantity = nil
            }
        }
        .navigationTitle("Today's Log")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Food Log Entry Row
struct FoodLogEntryRow: View {
    let entry: LoggedFoodEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.food.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)
                    
                    HStack(spacing: 8) {
                        if entry.mode == .weight {
                            Text(String(format: "%.0f %@", entry.quantity, entry.servingUnit.rawValue))
                                .font(.system(size: 13))
                                .foregroundColor(AppTheme.textSecondary)
                        } else {
                            Text(String(format: "%.1f serving%@", entry.quantity, entry.quantity > 1 ? "s" : ""))
                                .font(.system(size: 13))
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                }
                
                Spacer()
                
                Text(entry.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppTheme.textTertiary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white.opacity(0.06))
                    )
            }
            
            // Macro Pills
            HStack(spacing: 8) {
                MacroPill(value: "\(entry.scaledCalories)", label: "cal", color: AppTheme.calorieColor)
                MacroPill(value: String(format: "%.0f", entry.scaledProtein), label: "P", color: AppTheme.proteinColor)
                MacroPill(value: String(format: "%.0f", entry.scaledCarbs), label: "C", color: AppTheme.carbColor)
                MacroPill(value: String(format: "%.0f", entry.scaledFats), label: "F", color: AppTheme.fatColor)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(AppTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(AppTheme.border, lineWidth: 1)
                )
        )
    }
}
