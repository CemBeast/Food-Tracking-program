//
//  DictionaryView.swift
//  FoodTrackingApp
//
//  Created by Cem Beyenal on 10/28/24.
//
import SwiftUI

struct FoodItem: Identifiable {
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

struct DictionaryView: View {
    @Binding var selectedFood: FoodItem?
    @Binding var showGramsInput: Bool
    @State private var foodItems: [FoodItem] = []
    @State private var searchText: String = ""
    @State private var selectedFoodID: UUID? // Track the selected food item's ID
    @State private var highlightFoodID: UUID? // Track food item being highlighted briefly
    
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
            loadFoodDictionary()
        }
    }
    
    private var filteredFoodItems: [FoodItem] {
        foodItems.filter { foodItem in
            searchText.isEmpty || foodItem.name.localizedCaseInsensitiveContains(searchText)
        }
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
        guard let fileURL = Bundle.main.url(forResource: "FoodData", withExtension: "csv") else {
            print("CSV file not found.")
            return
        }
        
        do {
            let data = try String(contentsOf: fileURL)
            let rows = data.components(separatedBy: "\n")
            foodItems = rows.compactMap { row in
                let columns = row.components(separatedBy: ",")
                guard columns.count == 7,
                      let weight = Int(columns[1]),
                      let calories = Int(columns[3]),
                      let protein = Double(columns[4]),
                      let carbs = Double(columns[5]),
                      let fats = Double(columns[6]),
                      let servingType = Int(columns[2]) else { return nil }
                
                let servings: Int = servingType > 0 ? servingType : 0
                
                return FoodItem(name: columns[0],
                                weightInGrams: weight,
                                servings: servings,
                                calories: calories,
                                protein: (protein * 10).rounded() / 10.0,
                                carbs: (carbs * 10).rounded() / 10.0,
                                fats: (fats * 10).rounded() / 10.0)
            }
        } catch {
            print("Error loading CSV file: \(error)")
        }
    }
}

// MARK: - Preview

//struct DictionaryView_Previews: PreviewProvider {
//    static var previews: some View {
//        DictionaryView(
//            selectedFood: .constant(nil),
//            showGramsInput: .constant(false)
//        )
//    }
//}
