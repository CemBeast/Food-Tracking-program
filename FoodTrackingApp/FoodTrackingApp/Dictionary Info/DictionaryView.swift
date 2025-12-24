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
    
    // Backwards-compatible decode (old JSON won't have isFavorite)
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

        // ✅ default if missing
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
    // 🔒 Explicit keys make encoding/decoding bulletproof
    enum CodingKeys: String, CodingKey {
        case id, name, weightInGrams, servings, calories, protein, carbs, fats, servingUnit, isFavorite
    }
}

enum SortOption: String, CaseIterable, Identifiable {
    case name = "Name"
    case calories = "Calories"
    case protein = "Protein"
    case carbs = "Carbs"
    case fats = "Fats"
    case favorites = "Favorites"
    
    var id: String { self.rawValue}
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
    @Binding var selectedFoodID: UUID? // Track the selected food item's ID
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
        VStack {
            TextField("Search", text: $searchText)
                .padding(8)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(maxWidth: .infinity)
                .padding(.bottom, 8)
            
            Picker("Sort by", selection: $sortOption) {
                ForEach(SortOption.allCases) {option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            List {
                // Tracking food from the dictionary
                if !readOnly {
                    ForEach(filteredFoodItems) { foodItem in
                        Button(action: {}) {
                            content(for: foodItem, isSelected: foodItem.id == selectedFoodID)
                                .onTapGesture{
                                    selectedFood = foodItem
                                    selectedFoodID = foodItem.id // Highlight the selected item
                                    showMeasurementDialog = true
                                }
                                .swipeActions(edge: .leading, allowsFullSwipe: true) { //  swipe right to favorite
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
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    ForEach(filteredFoodItems) { foodItem in
                        content (for : foodItem, isSelected: false)
                            .onLongPressGesture {
                                print("Editing \(foodItem.name)")
                                foodToEdit = foodItem
                                isEditingFood = true
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: true) { // ✅ swipe right
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
                    .onDelete(perform: deleteItems)
                }
            }
        }
        .navigationTitle("Food Dictionary")
        .listStyle(PlainListStyle())
        // 3) Confirmation dialog for "Track by"
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
        case .favorites:
            //  ONLY favorites
            return base
                .filter { $0.isFavorite }
                .sorted { $0.name.lowercased() < $1.name.lowercased() }
        case .calories:
            return base.sorted { $0.calories > $1.calories }
        case .protein:
            return base.sorted { $0.protein > $1.protein }
        case .carbs:
            return base.sorted { $0.carbs > $1.carbs }
        case .fats:
            return base.sorted { $0.fats > $1.fats }
        }
    }
    
    private func toggleFavorite(_ foodItem: FoodItem) {
        guard let idx = foodModel.items.firstIndex(where: {$0.id == foodItem.id}) else  {return}
        foodModel.items[idx].isFavorite.toggle()
        foodModel.save()
    }
    
    private func content(for foodItem: FoodItem, isSelected: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(foodItem.name)
                    .font(.headline)

                Spacer()

                Button {
                    toggleFavorite(foodItem)
                } label: {
                    Image(systemName: foodItem.isFavorite ? "star.fill" : "star")
                        .foregroundColor(foodItem.isFavorite ? .yellow : .secondary)
                        .imageScale(.medium)
                }
                .buttonStyle(.plain)
            }
            
            HStack(spacing: 12) {
                macroColumn(icon: "number.circle.fill", label: "Servings", value: "\(foodItem.servings)", color: Color("TextPrimary").opacity(0.6))
                macroColumn(
                    icon: foodItem.servingUnit == .grams ? "scalemass.fill" : "eyedropper",
                    label: foodItem.servingUnit == .grams ? "Weight" : "Volume",
                    value: "\(foodItem.weightInGrams)\(foodItem.servingUnit == .grams ? "g" : "ml")",
                    color: Color("TextPrimary").opacity(0.6)
                )
                macroColumn(icon: "flame.fill", label: "Calories", value: "\(foodItem.calories)", color: .red)
                macroColumn(icon: "bolt.circle.fill", label: "Protein", value: String(format: "%.1fg", foodItem.protein), color: .yellow)
                macroColumn(icon: "leaf.circle.fill", label: "Carbs", value: String(format: "%.1fg", foodItem.carbs), color: .green)
                macroColumn(icon: "drop.circle.fill", label: "Fats", value: String(format: "%.1fg", foodItem.fats), color: .purple)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.75)
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(isSelected ? Color.blue.opacity(0.15) : Color.gray.opacity(0.05))
        .cornerRadius(10)
    }
    
    @ViewBuilder
    func macroColumn(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.caption)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
        .frame(minWidth: 50)
    }
    
    func loadFoodDictionary() {
        foodModel.load()
    }
    
    private func deleteItems(at offsets: IndexSet) {
        // figure out which FoodItems are being deleted
        let toDelete = offsets.map { filteredFoodItems[$0] }
        // remove them from the underlying model
        for item in toDelete {
            if let idx = foodModel.items.firstIndex(where: { $0.id == item.id}) {
                foodModel.items.remove(at: idx)
            }
        }
        // persist the change
        foodModel.save()
    }
}
