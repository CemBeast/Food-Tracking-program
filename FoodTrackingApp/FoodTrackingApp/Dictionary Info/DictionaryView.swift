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
    
    var isMeasuredByServing: Bool {
        return servings > 0
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

struct DictionaryView: View {
    @Binding var selectedFood: FoodItem?
    @Binding var showGramsInput: Bool
    @ObservedObject var foodModel: FoodModel
    @State private var searchText: String = ""
    @State private var selectedFoodID: UUID? // Track the selected food item's ID
    @State private var highlightFoodID: UUID? // Track food item being highlighted briefly
    @State private var sortOption: SortOption = .name
    
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
            
            List(filteredFoodItems) { foodItem in
                if !readOnly {
                    Button(action: {
                        selectedFood = foodItem
                        selectedFoodID = foodItem.id // Highlight the selected item
                        showGramsInput = true
                    }) {
                        content(for: foodItem, isSelected: foodItem.id == selectedFoodID)
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    content(for: foodItem, isSelected: false)
                }
            }
        }
        .navigationTitle("Food Dictionary")
        .listStyle(PlainListStyle())
        .onAppear {
            foodModel.load()
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
                    if foodItem.isMeasuredByServing {
                        Text("Servings")
                            .font(.callout)
                            .lineLimit(1) // Ensures the text stays on one line
                            .minimumScaleFactor(0.8) // Allows text to shrink slightly if necessary
                        Text("\(foodItem.servings)")
                            .font(.headline)
                    } else {
                        Text("Weight")
                            .font(.callout)
                            .lineLimit(1) // Ensures the text stays on one line
                            .minimumScaleFactor(0.8) // Allows text to shrink slightly if necessary
                        Text("\(foodItem.weightInGrams)g")
                            .font(.headline)
                    }
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
}
