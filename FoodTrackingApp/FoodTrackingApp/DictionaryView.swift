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
    var servings: Int // Represents the number of servings
    var calories: Int
    var protein: Double
    var carbs: Double
    var fats: Double
    
    var isMeasuredByServing: Bool {
        return servings > 0 // True if servings is greater than 0
    }
}

struct DictionaryView: View {
    @State private var foodItems: [FoodItem] = []
    @State private var searchText: String = ""

    let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        return formatter
    }()
    
    var body: some View {
        HStack {
                TextField("Search", text: $searchText)
                    .padding(8)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(maxWidth: .infinity)
            }
            .padding(.bottom, 0) // Remove extra space above the search bar
            Spacer(minLength: 0)
        List(foodItems.filter { foodItem in
            searchText.isEmpty || foodItem.name.localizedCaseInsensitiveContains(searchText)}) { foodItem in
            VStack(alignment: .leading) {
                Text(foodItem.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                    
                HStack {
                    VStack(alignment: .leading) {
                        if foodItem.isMeasuredByServing {
                            Text("Servings")
                            Text("\(foodItem.servings)")
                        } else {
                            Text("Weight")
                            Text("\(foodItem.weightInGrams)g")
                        }
                    }
                    .frame(maxWidth: .infinity) // Make this VStack take full width
                    VStack(alignment: .leading) {
                        Text("Calories")
                        Text("\(foodItem.calories)")
                    }
                    .frame(maxWidth: .infinity) // Make this VStack take full width
                    VStack(alignment: .leading) {
                        Text("Protein")
                        Text("\(formatter.string(from: NSNumber(value: foodItem.protein)) ?? "")g")
                    }
                    .frame(maxWidth: .infinity) // Make this VStack take full width
                    VStack(alignment: .leading) {
                        Text("Carbs")
                        Text("\(formatter.string(from: NSNumber(value: foodItem.carbs)) ?? "")g")
                    }
                    .frame(maxWidth: .infinity) // Make this VStack take full width
                    VStack(alignment: .leading) {
                        Text("Fats")
                        Text("\(formatter.string(from: NSNumber(value: foodItem.fats)) ?? "")g")
                    }
                    .frame(maxWidth: .infinity) // Make this VStack take full width
                }
            }
        }
        .navigationTitle("Food Dictionary")
        .listStyle(PlainListStyle())
        .padding(.top, 0) // Optional: Set top padding to 0
        .onAppear {
            loadFoodDictionary()
        }
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
                
                let servings: Int = servingType > 0 ? servingType : 0 // Use servingType directly if > 0
                
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
    }}

struct DictionaryViewPreview: PreviewProvider{
    static var previews: some View {
        DictionaryView() 
    }
}
