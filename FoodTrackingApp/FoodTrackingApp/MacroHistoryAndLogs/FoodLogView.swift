//
//  FoodLogView.swift
//  FoodTrackingApp
//
//  Created by Cem Beyenal on 5/21/25.
//
import SwiftUI

struct FoodLogView: View {
    @State private var foodToEditQuantity: LoggedFoodEntry?
    @State private var quickEntryToEdit: LoggedFoodEntry?
    @ObservedObject var viewModel: MacroTrackerViewModel
    @ObservedObject var foodModel: FoodModel
    @State private var entryToAddToDictionary: LoggedFoodEntry?

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            if viewModel.foodLog.isEmpty {
                // Empty State
                VStack(spacing: 16.scaled) {
                    Image(systemName: "fork.knife.circle")
                        .font(.system(size: 56.scaled, weight: .light))
                        .foregroundColor(AppTheme.textTertiary)
                    
                    Text("No Foods Logged")
                        .font(.system(size: 20.scaled, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Text("Start tracking your meals to see them here")
                        .font(.system(size: 14.scaled))
                        .foregroundColor(AppTheme.textSecondary)
                }
            } else {
                List {
                    ForEach(viewModel.foodLog) { entry in
                        FoodLogEntryRow(entry: entry) {
                            entryToAddToDictionary = entry
                        }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 6.scaled, leading: 20.scaled, bottom: 6.scaled, trailing: 20.scaled))
                            .onLongPressGesture {
                                if entry.isQuickEntry {
                                    quickEntryToEdit = entry
                                } else {
                                    foodToEditQuantity = entry
                                }
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
        .sheet(item: $quickEntryToEdit) { entry in
            QuickMacroTrackView(editing: entry) { updatedFood in
                viewModel.updateQuickEntry(entry, with: updatedFood)
            }
        }
        .addToDictionarySheet(entry: $entryToAddToDictionary, foodModel: foodModel)
        .navigationTitle("Today's Log")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Food Log Entry Row
struct FoodLogEntryRow: View {
    let entry: LoggedFoodEntry
    /// Shown as a "+ Dictionary" button on Quick Track entries when provided.
    var onAddToDictionary: (() -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12.scaled) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4.scaled) {
                    Text(entry.food.name)
                        .font(.system(size: 16.scaled, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)
                    
                    HStack(spacing: 8.scaled) {
                        if entry.isQuickEntry {
                            // Quick Track entries have no real quantity, so show a badge instead.
                            HStack(spacing: 4.scaled) {
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 10.scaled, weight: .semibold))
                                Text("Quick")
                                    .font(.system(size: 12.scaled, weight: .semibold))
                            }
                            .foregroundColor(AppTheme.textPrimary)
                            .padding(.horizontal, 8.scaled)
                            .padding(.vertical, 3.scaled)
                            .background(
                                Capsule().fill(Color.white.opacity(0.12))
                            )
                            .accessibilityLabel("Quick Track entry")

                            if let onAddToDictionary {
                                Button(action: onAddToDictionary) {
                                    HStack(spacing: 3.scaled) {
                                        Image(systemName: "plus")
                                            .font(.system(size: 10.scaled, weight: .bold))
                                        Text("Dictionary")
                                            .font(.system(size: 12.scaled, weight: .semibold))
                                    }
                                    .foregroundColor(AppTheme.textSecondary)
                                    .padding(.horizontal, 8.scaled)
                                    .padding(.vertical, 3.scaled)
                                    .overlay(
                                        Capsule().stroke(AppTheme.border, lineWidth: 1)
                                    )
                                }
                                // Borderless so tapping the row elsewhere doesn't trigger it.
                                .buttonStyle(.borderless)
                                .accessibilityLabel("Add to dictionary")
                            }
                        } else {
                            Text(entry.quantityLabel)
                                .font(.system(size: 13.scaled))
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                }
                
                Spacer()
                
                Text(entry.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 12.scaled, weight: .medium))
                    .foregroundColor(AppTheme.textTertiary)
                    .padding(.horizontal, 10.scaled)
                    .padding(.vertical, 6.scaled)
                    .background(
                        RoundedRectangle(cornerRadius: 6.scaled)
                            .fill(Color.white.opacity(0.06))
                    )
            }
            
            // Macro Pills
            HStack(spacing: 8.scaled) {
                MacroPill(value: "\(entry.scaledCalories)", label: "cal", color: AppTheme.calorieColor)
                MacroPill(value: String(format: "%.0f", entry.scaledProtein), label: "P", color: AppTheme.proteinColor)
                MacroPill(value: String(format: "%.0f", entry.scaledCarbs), label: "C", color: AppTheme.carbColor)
                MacroPill(value: String(format: "%.0f", entry.scaledFats), label: "F", color: AppTheme.fatColor)
            }
        }
        .padding(16.scaled)
        .background(
            RoundedRectangle(cornerRadius: 14.scaled)
                .fill(AppTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 14.scaled)
                        .stroke(AppTheme.border, lineWidth: 1)
                )
        )
    }
}

// MARK: - Add Quick Entry to Dictionary
extension LoggedFoodEntry {
    /// A dictionary-ready food built from a quick entry: same name and
    /// (scaled) macros, defaulted to 100 g so the user can adjust the weight.
    var dictionaryDraft: FoodItem {
        FoodItem(
            name: food.name,
            weightInGrams: 100,
            servings: 1,
            calories: scaledCalories,
            protein: scaledProtein,
            carbs: scaledCarbs,
            fats: scaledFats,
            servingUnit: .grams
        )
    }
}

private struct AddToDictionarySheet: ViewModifier {
    @Binding var entry: LoggedFoodEntry?
    let foodModel: FoodModel
    // Set on save, shown once the sheet has fully dismissed (presenting an
    // alert while a sheet is still closing is unreliable).
    @State private var pendingMessage: String?
    @State private var alertMessage: String?

    func body(content: Content) -> some View {
        content
            .sheet(item: $entry, onDismiss: {
                alertMessage = pendingMessage
                pendingMessage = nil
            }) { entry in
                EditFoodItemView(
                    foodItem: entry.dictionaryDraft,
                    isAdding: true,
                    onSave: { food in
                        pendingMessage = foodModel.add(food)
                            ? "\"\(food.name)\" was added to your dictionary."
                            : "A food named \"\(food.name)\" is already in your dictionary, so nothing was added."
                    },
                    onCancel: { }
                )
            }
            .alert(
                alertMessage ?? "",
                isPresented: Binding(
                    get: { alertMessage != nil },
                    set: { if !$0 { alertMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) { }
            }
    }
}

extension View {
    func addToDictionarySheet(entry: Binding<LoggedFoodEntry?>, foodModel: FoodModel) -> some View {
        modifier(AddToDictionarySheet(entry: entry, foodModel: foodModel))
    }
}
