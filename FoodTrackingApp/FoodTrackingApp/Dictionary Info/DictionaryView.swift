//
//  DictionaryView.swift
//  FoodTrackingApp
//
//  Created by Cem Beyenal on 10/28/24.
//
import SwiftUI

struct FoodItem: Identifiable, Codable {
    var id = UUID()
    var name: String
    var weightInGrams: Int
    var servings: Int
    var calories: Int
    var protein: Double
    var carbs: Double
    var fats: Double
    var servingUnit: ServingUnit
    var isFavorite: Bool = false
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try c.decode(String.self, forKey: .name)
        weightInGrams = try c.decode(Int.self, forKey: .weightInGrams)
        servings = try c.decode(Int.self, forKey: .servings)
        calories = try c.decode(Int.self, forKey: .calories)
        protein = try c.decode(Double.self, forKey: .protein)
        carbs = try c.decode(Double.self, forKey: .carbs)
        fats = try c.decode(Double.self, forKey: .fats)
        servingUnit = try c.decode(ServingUnit.self, forKey: .servingUnit)
        isFavorite = try c.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
    }
    
    init(
            name: String,
            weightInGrams: Int,
            servings: Int,
            calories: Int,
            protein: Double,
            carbs: Double,
            fats: Double,
            servingUnit: ServingUnit,
            isFavorite: Bool = false
        ) {
            self.id = UUID()
            self.name = name
            self.weightInGrams = weightInGrams
            self.servings = servings
            self.calories = calories
            self.protein = protein
            self.carbs = carbs
            self.fats = fats
            self.servingUnit = servingUnit
            self.isFavorite = isFavorite
        }
    
    enum CodingKeys: String, CodingKey {
        case id, name, weightInGrams, servings, calories, protein, carbs, fats, servingUnit, isFavorite
    }
}

enum SortOption: String, CaseIterable, Identifiable {
    case name = "Name"
    case calories = "Calories"
    case favorites = "Favorites"
    
    var id: String { self.rawValue }
}

enum ServingUnit: String, Codable, CaseIterable, Identifiable {
    case grams = "g"
    case milliliters = "ml"
    var id: String { self.rawValue }
}

enum MeasurementMode: String, Codable, CaseIterable, Identifiable {
    case weight, serving
    var id: String { self.rawValue }
}

struct DictionaryView: View {
    @Binding var selectedFood: FoodItem?
    @Binding var showGramsInput: Bool
    @Binding var selectedFoodID: UUID?
    @Binding var selectedMeasurementMode: MeasurementMode?
    @ObservedObject var foodModel: FoodModel
    @State private var searchText: String = ""
    @State private var sortOption: SortOption = .name
    @State private var showMeasurementDialog: Bool = false
    @State private var isEditingFood: Bool = false
    @State private var foodToEdit: FoodItem? = nil
    
    var readOnly: Bool = false

    let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16))
                    .foregroundColor(AppTheme.textTertiary)
                
                TextField("Search foods...", text: $searchText)
                    .font(.system(size: 16))
                    .foregroundColor(AppTheme.textPrimary)
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(AppTheme.textTertiary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppTheme.border, lineWidth: 1)
                    )
            )
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            // Sort Picker
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(SortOption.allCases) { option in
                        Button {
                            withAnimation(.easeOut(duration: 0.2)) {
                                sortOption = option
                            }
                        } label: {
                            Text(option.rawValue)
                                .font(.system(size: 13, weight: sortOption == option ? .semibold : .medium))
                                .foregroundColor(sortOption == option ? .black : AppTheme.textSecondary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(sortOption == option ? Color.white : Color.white.opacity(0.06))
                                )
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 12)
            
            // Food List
            List {
                if !readOnly {
                    ForEach(filteredFoodItems) { foodItem in
                        Button(action: {}) {
                            FoodItemRow(foodItem: foodItem, isSelected: foodItem.id == selectedFoodID, onToggleFavorite: {
                                toggleFavorite(foodItem)
                            })
                            .onTapGesture {
                                selectedFood = foodItem
                                selectedFoodID = foodItem.id
                                showMeasurementDialog = true
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button {
                                    toggleFavorite(foodItem)
                                } label: {
                                    Label(
                                        foodItem.isFavorite ? "Unfavorite" : "Favorite",
                                        systemImage: foodItem.isFavorite ? "star.slash" : "star.fill"
                                    )
                                }
                                .tint(.yellow)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                    }
                } else {
                    ForEach(filteredFoodItems) { foodItem in
                        FoodItemRow(foodItem: foodItem, isSelected: false, onToggleFavorite: {
                            toggleFavorite(foodItem)
                        })
                        .onLongPressGesture {
                            foodToEdit = foodItem
                            isEditingFood = true
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                toggleFavorite(foodItem)
                            } label: {
                                Label(
                                    foodItem.isFavorite ? "Unfavorite" : "Favorite",
                                    systemImage: foodItem.isFavorite ? "star.slash" : "star.fill"
                                )
                            }
                            .tint(.yellow)
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                    }
                    .onDelete(perform: deleteItems)
                }
            }
            .listStyle(PlainListStyle())
            .scrollContentBackground(.hidden)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("Food Dictionary")
        .navigationBarTitleDisplayMode(.large)
        .confirmationDialog(
            "Track by",
            isPresented: $showMeasurementDialog,
            titleVisibility: .visible
        ) {
            if let unit = selectedFood?.servingUnit {
                Button(unit == .milliliters ? "Volume" : "Weight") {
                    selectedMeasurementMode = .weight
                    showGramsInput = true
                }
            }
            Button("Servings") {
                selectedMeasurementMode = .serving
                showGramsInput = true
            }
            Button("Cancel", role: .cancel) {
                selectedFood = nil
                selectedFoodID = nil
            }
        }
        .sheet(item: $foodToEdit) { item in
            EditFoodItemView(
                foodItem: item,
                onSave: { updated in
                    if let index = foodModel.items.firstIndex(where: { $0.id == updated.id }) {
                        foodModel.items[index] = updated
                        foodModel.save()
                    }
                    foodToEdit = nil
                },
                onCancel: {
                    foodToEdit = nil
                }
            )
        }
    }
    
    private var filteredFoodItems: [FoodItem] {
        let base = foodModel.items.filter { foodItem in
            searchText.isEmpty || foodItem.name.localizedCaseInsensitiveContains(searchText)
        }
        switch sortOption {
        case .name:
            return base.sorted { $0.name.lowercased() < $1.name.lowercased() }
        case .calories:
            return base.sorted { $0.calories > $1.calories }
        case .favorites:
            return base
                .filter { $0.isFavorite }
                .sorted { $0.name.lowercased() < $1.name.lowercased() }
        }
    }
    
    private func toggleFavorite(_ foodItem: FoodItem) {
        guard let idx = foodModel.items.firstIndex(where: {$0.id == foodItem.id}) else { return }
        foodModel.items[idx].isFavorite.toggle()
        foodModel.save()
    }
    
    func loadFoodDictionary() {
        foodModel.load()
    }
    
    private func deleteItems(at offsets: IndexSet) {
        let toDelete = offsets.map { filteredFoodItems[$0] }
        for item in toDelete {
            if let idx = foodModel.items.firstIndex(where: { $0.id == item.id}) {
                foodModel.items.remove(at: idx)
            }
        }
        foodModel.save()
    }
}

// MARK: - Food Item Row
struct FoodItemRow: View {
    let foodItem: FoodItem
    let isSelected: Bool
    let onToggleFavorite: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header with name and favorite
            HStack {
                Text(foodItem.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)

                Spacer()

                Button {
                    onToggleFavorite()
                } label: {
                    Image(systemName: foodItem.isFavorite ? "star.fill" : "star")
                        .font(.system(size: 16))
                        .foregroundColor(foodItem.isFavorite ? .yellow : AppTheme.textTertiary)
                }
                .buttonStyle(.plain)
            }
            
            // Serving info
            HStack(spacing: 16) {
                Label("\(foodItem.servings) srv", systemImage: "number.circle")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textSecondary)
                
                Label("\(foodItem.weightInGrams)\(foodItem.servingUnit.rawValue)", systemImage: foodItem.servingUnit == .grams ? "scalemass" : "drop")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textSecondary)
            }
            
            // Macro pills
            HStack(spacing: 8) {
                MacroPill(value: "\(foodItem.calories)", label: "cal", color: AppTheme.calorieColor)
                MacroPill(value: String(format: "%.0f", foodItem.protein), label: "P", color: AppTheme.proteinColor)
                MacroPill(value: String(format: "%.0f", foodItem.carbs), label: "C", color: AppTheme.carbColor)
                MacroPill(value: String(format: "%.0f", foodItem.fats), label: "F", color: AppTheme.fatColor)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(AppTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isSelected ? Color.white.opacity(0.5) : AppTheme.border, lineWidth: isSelected ? 2 : 1)
                )
        )
    }
}

// MARK: - Macro Pill
struct MacroPill: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(color.opacity(0.7))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.12))
        )
    }
}
