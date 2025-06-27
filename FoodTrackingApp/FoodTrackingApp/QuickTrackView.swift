import SwiftUI

struct QuickMacroTrackView: View {
    @Environment(\.presentationMode) var presentationMode

    @State private var name = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fats = ""

    var onLog: (FoodItem) -> Void

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Quick Track Food")) {
                    TextField("Food Name (optional)", text: $name)
                    TextField("Calories", text: $calories)
                        .keyboardType(.decimalPad)
                    TextField("Protein (g)", text: $protein)
                        .keyboardType(.decimalPad)
                    TextField("Carbs (g)", text: $carbs)
                        .keyboardType(.decimalPad)
                    TextField("Fats (g)", text: $fats)
                        .keyboardType(.decimalPad)
                }

                Button("Log Macros") {
                    guard let cal = Int(calories),
                          let prot = Double(protein),
                          let carb = Double(carbs),
                          let fat = Double(fats) else {
                        return // Optionally show validation alert
                    }

                    let quickFood = FoodItem(
                        name: name.isEmpty ? "Quick Entry" : name,
                        weightInGrams: 0,
                        servings: 1,
                        calories: cal,
                        protein: prot,
                        carbs: carb,
                        fats: fat,
                        servingUnit: .grams
                    )

                    onLog(quickFood)
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .navigationTitle("Quick Track")
        }
    }
}
