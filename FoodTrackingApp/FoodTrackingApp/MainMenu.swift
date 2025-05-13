//
//  MainMenu.swift
//  FoodTrackingApp
//
//  Created by Cem Beyenal on 10/28/24.
//
import SwiftUI

struct CustomButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(maxWidth: .infinity)
            .background(.red)
            .foregroundColor(.white)
            .cornerRadius(8)
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct MainMenu: View {
    // viewModel to track todays macros
    @StateObject private var viewModel = MacroTrackerViewModel()
    // foodModel is the food dictionary
    @StateObject private var foodModel = FoodModel()

    @State private var selectedFood: FoodItem? = nil
    @State private var showFoodSelection = false
    @State private var showGramsInput = false
    @State private var gramsOrServings: Int? = nil
    
    @State private var showManual = false
    @State private var showScanner = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Todays Macros
                FoodMacrosDisplay(
                    calories: viewModel.calories,
                    protein: viewModel.protein,
                    carbs: viewModel.carbs,
                    fats: viewModel.fats
                )

                Spacer()
                Menu("Add New Food") {
                    Button("Add Manually") {
                        showManual = true
                    }
                    Button("Scan Barcode") {
                        showScanner = true
                    }
                }
                .buttonStyle(CustomButtonStyle())
                .sheet(isPresented: $showManual) {
                    AddFoodView(onAdd: {newFood in
                        foodModel.add(newFood)
                    })
                }
                .sheet(isPresented: $showScanner) {
                    BarcodeScannerView(foodModel: foodModel)
                }
                
                
                // View the food dictionary only
                NavigationLink(destination: DictionaryView(
                    selectedFood: $selectedFood,
                    showGramsInput: $showGramsInput,
                    foodModel: foodModel,
                    readOnly: true
                )) {
                    Text("View Food Dictionary")
                        .buttonStyle(CustomButtonStyle())
                }
                
                // Track food from within the dictionary view
                Button(action: {
                    showFoodSelection.toggle()
                }) {
                    Text("Select Food to Track")
                        .buttonStyle(CustomButtonStyle())
                }
                .sheet(isPresented: $showFoodSelection) {
                    DictionaryView(
                        selectedFood: $selectedFood,
                        showGramsInput: $showGramsInput,
                        foodModel: foodModel,
                        readOnly: false
                    )
                    if showGramsInput, let food = selectedFood {
                        GramsOrServingsInput(
                            food: food,
                            gramsOrServings: $gramsOrServings,
                            showGramsInput: $showGramsInput,
                            updateMacros: { calculatedCalories, calculatedFats, calculatedProtein, calculatedCarbs in
                                viewModel.calories += Int(calculatedCalories)
                                viewModel.fats += calculatedFats
                                viewModel.protein += calculatedProtein
                                viewModel.carbs += calculatedCarbs
                            }
                        )
                    }
                }
                
                // Save Button
                Button("Clear Macro History") {
                    viewModel.clearHistory()
                }
                   
                // History Button
                NavigationLink(destination: MacroHistoryView(history: viewModel.history)) {
                    Text("View History")
                        .buttonStyle(CustomButtonStyle())
                }
                
                Spacer()
            }
            .navigationTitle("Food Tracking Menu")
        }
    }
}

//struct MainMenuPreviews: PreviewProvider {
//    static var previews: some View {
//        MainMenu()
//    }
//}

