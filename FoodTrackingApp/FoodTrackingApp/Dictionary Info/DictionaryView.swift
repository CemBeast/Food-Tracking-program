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
    init(
            name: String,
            weightInGrams: Int,
            servings: Int,
            calories: Int,
            protein: Double,
            carbs: Double,
            fats: Double,
            servingUnit: ServingUnit
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
        }
    // 🔒 Explicit keys make encoding/decoding bulletproof
    enum CodingKeys: String, CodingKey {
        case id, name, weightInGrams, servings, calories, protein, carbs, fats, servingUnit
    }
}

enum SortOption: String, CaseIterable, Identifiable {
    case name = "Name"
    case calories = "Calories"
    case protein = "Protein"
    case carbs = "Carbs"
    case fats = "Fats"
    
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
                        }
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
        var result = foodModel.items.filter { foodItem in
            searchText.isEmpty || foodItem.name.localizedCaseInsensitiveContains(searchText)
        }
        
        result.sort { (a: FoodItem, b: FoodItem) -> Bool in
            switch sortOption {
            case .name:
                return a.name.lowercased() < b.name.lowercased()
            case .calories:
                return a.calories > b.calories
            case .protein:
                return a.protein > b.protein
            case .carbs:
                return a.carbs > b.carbs
            case .fats:
                return a.fats > b.fats
            }
        }
        return result
    }
    
    private func content(for foodItem: FoodItem, isSelected: Bool) -> some View {
        VStack(alignment: .leading) {
            Text(foodItem.name)
                .font(.title2)
                .fontWeight(.semibold)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Servings")
                        .font(.callout)
                        .lineLimit(1) // Ensures the text stays on one line
                        .minimumScaleFactor(0.8) // Allows text to shrink slightly if necessary
                    Text("\(foodItem.servings)")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                
                VStack(alignment: .leading) {
                    Text(foodItem.servingUnit == .grams ? "Weight" : "Volume")
                        .font(.callout)
                        .lineLimit(1) // Ensures the text stays on one line
                        .minimumScaleFactor(0.8) // Allows text to shrink slightly if necessary
                    Text("\(foodItem.weightInGrams)\(foodItem.servingUnit == .grams ? "g" : "ml")")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                
                VStack(alignment: .leading) {
                    Text("Calories")
                        .font(.callout)
                        .lineLimit(1) // Ensures the text stays on one line
                        .minimumScaleFactor(0.8) // Allows text to shrink slightly if necessary
                    Text("\(foodItem.calories)")
                        .font(.headline)
                    
                }
                .frame(maxWidth: .infinity)
                
                VStack(alignment: .leading) {
                    Text("Protein")
                        .font(.callout)
                    Text("\(formatter.string(from: NSNumber(value: foodItem.protein)) ?? "")g")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                
                VStack(alignment: .leading) {
                    Text("Carbs")
                        .font(.callout)
                    Text("\(formatter.string(from: NSNumber(value: foodItem.carbs)) ?? "")g")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                
                VStack(alignment: .leading) {
                    Text("Fats")
                        .font(.callout)
                    Text("\(formatter.string(from: NSNumber(value: foodItem.fats)) ?? "")g")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(isSelected ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1)) // Highlight if selected
        .cornerRadius(8)
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
