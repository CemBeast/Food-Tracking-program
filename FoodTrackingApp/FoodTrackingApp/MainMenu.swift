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
    @State private var selectedFoodID: UUID? 
    @State private var showFoodSelection = false
    @State private var showGramsInput = false
    @State private var gramsOrServings: Int? = nil
    @State private var selectedMeasurementMode: MeasurementMode? = nil   // ← New
    
    // For manually adding foods or using barcode
    @State private var showManual = false
    @State private var showScanner = false
    
    // For tracking through barcode scan
    @State private var scannedItem: FoodItem? = nil
    @State private var showScannerTracking = false
    @State private var showConfirmScannedItem = false

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
                    selectedFoodID: $selectedFoodID,
                    selectedMeasurementMode: $selectedMeasurementMode,
                    foodModel: foodModel,
                    readOnly: true
                )) {
                    Text("View Food Dictionary")
                }
                .buttonStyle(CustomButtonStyle())
                
                // Track food by scanning a barcode
                Button("Track Food from Barcode") {
                    showScannerTracking = true
                }
                .sheet(isPresented: $showScannerTracking) {
                    ScannerViewForTracking { item in
                        print("✅ Scanned food: \(item.name)")
                        scannedItem = item
                        showConfirmScannedItem = true
                    }
                }
                .sheet(item: $scannedItem) { food in
                    GramsOrServingsInput(
                        food: food,
                        mode: food.servingUnit == .grams ? .weight : .serving,
                        gramsOrServings: $gramsOrServings,
                        showGramsInput: .constant(true),  // or bind this to a local @State if needed
                        updateMacros: { cals, fats, prot, carbs in
                            viewModel.logFood(food, gramsOrServings: gramsOrServings ?? 1, mode: food.servingUnit == .grams ? .weight : .serving)
                                scannedItem = nil
                        }
                    )
                }
                .buttonStyle(CustomButtonStyle())
                
                // Track food from within the dictionary view
                Button(action: {
                    showFoodSelection.toggle()
                }) {
                    Text("Select Food to Track")
                        .buttonStyle(CustomButtonStyle())
                }
                .sheet(
                    isPresented: $showFoodSelection,
                    onDismiss: {
                        // Reset everything when the sheet is swiped down
                        selectedFood               = nil
                        selectedFoodID             = nil
                        selectedMeasurementMode    = nil
                        showGramsInput             = false
                        gramsOrServings            = nil
                    }
                )   {
                    ZStack {
                        DictionaryView(
                            selectedFood: $selectedFood,
                            showGramsInput: $showGramsInput,
                            selectedFoodID: $selectedFoodID,
                            selectedMeasurementMode: $selectedMeasurementMode,
                            foodModel: foodModel,
                            readOnly: false
                        )
                        // model of grams/serving overlay
                        if showGramsInput,
                            let food = selectedFood,
                            let mode = selectedMeasurementMode
                        {
                            GramsOrServingsInput(
                                food: food,
                                mode: mode,
                                gramsOrServings: $gramsOrServings,
                                showGramsInput: $showGramsInput,
                                updateMacros: { cals, fats, prot, carbs in
                                    viewModel.logFood(food, gramsOrServings: gramsOrServings ?? 1, mode: food.servingUnit == .grams ? .weight : .serving)
                                }
                            )
                        }
                    }
                    // Once as showGramsInput is false we clear the seciton
                    .onChange(of: showGramsInput) { done in
                        if done == false {
                            selectedFood = nil
                            selectedFoodID = nil
                            selectedMeasurementMode    = nil
                        }
                    }
                }
                .buttonStyle(CustomButtonStyle())
                
                // Save Button
                Button("Clear Macro History") {
                    viewModel.clearHistory()
                }
                .buttonStyle(CustomButtonStyle())
                  
                // View food ate today
                NavigationLink(destination: FoodLogView(foods: viewModel.foodLog)) {
                    Text("View Foods Eaten Today")
                }
                .buttonStyle(CustomButtonStyle())
                
                // History Button
                NavigationLink(destination: MacroHistoryView(history: viewModel.history)) {
                    Text("View History")
                        .buttonStyle(CustomButtonStyle())
                }
                .buttonStyle(CustomButtonStyle())
                
                Button("Clear Daily Macros") {
                    viewModel.resetMacros()
                }
                .buttonStyle(CustomButtonStyle())
                
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

