//
//  MainMenu.swift
//  FoodTrackingApp
//
//  Created by Cem Beyenal on 10/28/24.
//
import SwiftUI

struct CustomButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 12) {
            // Placeholder for a logo/icon
            Image(systemName: "sparkles")
                .font(.headline)
                .foregroundColor(.white)
                .padding(8)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                        .shadow(color: .white.opacity(0.2), radius: 4, x: 1, y: 2)
                )

            configuration.label
                .font(.system(size: 16, weight: .semibold, design: .rounded))
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(colors: [.blue.opacity(0.8), .purple.opacity(0.8)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .cornerRadius(16)
                .shadow(color: .purple.opacity(configuration.isPressed ? 0.2 : 0.4),
                        radius: configuration.isPressed ? 4 : 10,
                        x: 0, y: configuration.isPressed ? 2 : 6)
        )
        .foregroundColor(.white)
        .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: configuration.isPressed)
    }
}

struct SectionCard<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .padding(.horizontal)

            VStack(spacing: 10) {
                content
                    .buttonStyle(CustomButtonStyle())
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 16).fill(Color("CardBackground")))
            .shadow(radius: 2)
        }
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
    @State private var gramsOrServings: Double? = nil
    @State private var selectedMeasurementMode: MeasurementMode? = nil   // ← New
    
    // For manually adding foods or using barcode
    @State private var showManual = false
    @State private var showScanner = false
    
    // For tracking through barcode scan
    @State private var scannedItem: FoodItem? = nil
    @State private var showScannerTracking = false
    @State private var showEditGoals = false
    
    // For confirming user wants to clear daily/history macros
    @State private var showingClearDailyMacrosAlert = false
    @State private var showingClearHistoryMacrosAlert = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Stationary view of macros consumed/left
                DailyMacrosDisplay(
                    calories: viewModel.calories,
                    protein: viewModel.protein,
                    carbs: viewModel.carbs,
                    fats: viewModel.fats,
                    calorieGoal: viewModel.caloriesGoal,
                    proteinGoal: viewModel.proteinGoal,
                    carbGoal: viewModel.carbGoal,
                    fatGoal: viewModel.fatGoal
                )
                
                ScrollView {
                    VStack(spacing: 16) {
                        // MARK: Food Dictionary Section
                        SectionCard(title: "Food Dictionary") {
                            Button("Add Food Manually") {
                                showManual = true
                            }
                            Button("Add Food by Barcode") {
                                showScanner = true
                            }
                            NavigationLink(destination:
                                DictionaryView(
                                    selectedFood: $selectedFood,
                                    showGramsInput: $showGramsInput,
                                    selectedFoodID: $selectedFoodID,
                                    selectedMeasurementMode: $selectedMeasurementMode,
                                    foodModel: foodModel,
                                    readOnly: true
                                )
                            ) {
                                Text("View Food Dictionary")
                            }
                        }

                        // MARK: Tracking Food Section
                        SectionCard(title: "Tracking Food") {
                            Button("Track Food from Barcode") {
                                showScannerTracking = true
                            }
                            Button("Select Food to Track") {
                                showFoodSelection.toggle()
                            }
                        }

                        // MARK: History Section
                        SectionCard(title: "History") {
                            NavigationLink(destination: FoodLogView(viewModel: viewModel)) {
                                Text("View Foods Eaten Today")
                            }
                            NavigationLink(destination: MacroHistoryView(viewModel: viewModel)) {
                                Text("View Macro History")
                            }
                            Button("Clear Daily Macros") {
                                showingClearDailyMacrosAlert = true
                            }
                            .alert("Are you sure?", isPresented: $showingClearDailyMacrosAlert) {
                                Button("Clear", role: .destructive) {
                                    viewModel.resetMacros()
                                }
                                Button("Cancel", role: .cancel) {}
                            } message : {
                                Text("This will reset today's tracked macros.")
                            }
                            Button("Clear History") {
                                showingClearHistoryMacrosAlert = true
                            }
                            .alert("Are you sure?", isPresented: $showingClearHistoryMacrosAlert) {
                                Button("Clear", role: .destructive) {
                                    viewModel.clearHistory()
                                }
                                Button("Cancel", role: .cancel) {}
                            } message: {
                                Text("This will permanently delete all saved food logs")
                            }
                        }

                        // MARK: Personal Section
                        SectionCard(title: "Personal") {
                            Button("Edit Macro Goals") {
                                showEditGoals = true
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .background(Color("PrimaryBackground"))
            // MARK: Sheets for Food Dictionary
            .sheet(isPresented: $showManual) {
                AddFoodView(onAdd: { newFood in
                    foodModel.add(newFood)
                })
            }
            .sheet(isPresented: $showScanner) {
                BarcodeTrackingWrapperView(viewModel: foodModel)
            }

            // MARK: Sheet for Tracking Food by Barcode
            .sheet(isPresented: $showScannerTracking) {
                ScannerViewForTracking { item in
                    showScannerTracking = false
                    scannedItem = item
                }
            }
            .sheet(item: $scannedItem) { food in
                GramsOrServingsInput(
                    food: food,
                    mode: food.servingUnit == .grams ? .weight : .serving,
                    gramsOrServings: $gramsOrServings,
                    showGramsInput: .constant(true),
                    updateMacros: { _, _, _, _ in
                        // Ensure we have a valid Double quantity (e.g. 1.6)
                        let actualQuantity = gramsOrServings ?? 0.0
                        viewModel.logFood(
                            food,
                            gramsOrServings: actualQuantity,
                            mode: food.servingUnit == .grams ? .weight : .serving
                        )
                        scannedItem = nil
                    }
                )
            }

            // MARK: Sheet for Selecting Food from Dictionary
            .sheet(
                isPresented: $showFoodSelection,
                onDismiss: {
                    selectedFood = nil
                    selectedFoodID = nil
                    selectedMeasurementMode = nil
                    showGramsInput = false
                    gramsOrServings = nil
                }
            ) {
                ZStack {
                    DictionaryView(
                        selectedFood: $selectedFood,
                        showGramsInput: $showGramsInput,
                        selectedFoodID: $selectedFoodID,
                        selectedMeasurementMode: $selectedMeasurementMode,
                        foodModel: foodModel,
                        readOnly: false
                    )
                    if showGramsInput,
                       let food = selectedFood,
                       let mode = selectedMeasurementMode
                    {
                        GramsOrServingsInput(
                            food: food,
                            mode: mode,
                            gramsOrServings: $gramsOrServings,
                            showGramsInput: $showGramsInput,
                            updateMacros: { _, _, _, _ in
                                // Ensure we have a valid Double quantity (e.g. 1.6)
                                let actualQuantity = gramsOrServings ?? 0.0
                                viewModel.logFood(food,
                                                  gramsOrServings: actualQuantity,
                                                  mode: mode)
                            }
                        )
                    }
                }
                .onChange(of: showGramsInput) { done in
                    if done == false {
                        selectedFood = nil
                        selectedFoodID = nil
                        selectedMeasurementMode = nil
                    }
                }
            }

            // MARK: Sheet for Editing Goals
            .sheet(isPresented: $showEditGoals) {
                EditGoalsView(
                    calorieGoal: $viewModel.caloriesGoal,
                    proteinGoal: $viewModel.proteinGoal,
                    carbGoal: $viewModel.carbGoal,
                    fatGoal: $viewModel.fatGoal
                )
            }
        }
    }
}
//
//struct MainMenuPreviews: PreviewProvider {
//    static var previews: some View {
//        MainMenu()
//    }
//}

