//
//  MainMenu.swift
//  FoodTrackingApp
//
//  Created by Cem Beyenal on 10/28/24.
//
import SwiftUI

// MARK: - Section Card (Updated)
struct SectionCard<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: title)

            VStack(spacing: 10) {
                content
            }
            .cardStyle()
        }
    }
}

// MARK: - Food Dictionary Tab
struct FoodDictionaryTab: View {
    @Binding var showManual: Bool
    @Binding var showScanner: Bool
    @Binding var showMealBuilder: Bool
    @Binding var selectedFood: FoodItem?
    @Binding var selectedFoodID: UUID?
    @Binding var showGramsInput: Bool
    @Binding var selectedMeasurementMode: MeasurementMode?
    var foodModel: FoodModel
    @Binding var showDietPrompt: Bool
    @Binding var pendingAction: (() -> Void)?

    var body: some View {
        SectionCard(title: "Food Dictionary") {
            Button {
                showManual = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                    Text("Add Food Manually")
                }
            }
            .buttonStyle(SleekButtonStyle())
            
            Button {
                showScanner = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "barcode.viewfinder")
                        .font(.system(size: 18))
                    Text("Add Food by Barcode")
                }
            }
            .buttonStyle(SleekButtonStyle())
            
            Button {
                showMealBuilder = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "square.stack.3d.up.fill")
                        .font(.system(size: 18))
                    Text("Create a Meal")
                }
            }
            .buttonStyle(SleekButtonStyle())
            
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
                HStack(spacing: 12) {
                    Image(systemName: "book.fill")
                        .font(.system(size: 18))
                Text("View Food Dictionary")
                }
            }
            .buttonStyle(SleekButtonStyle())
        }
    }
}

// MARK: - Track Food Tab
struct TrackFoodTab: View {
    @Binding var showFoodSelection: Bool
    @Binding var showScannerTracking: Bool
    @Binding var showQuickTracking: Bool

    var body: some View {
        SectionCard(title: "Track Food") {
            Button {
                showScannerTracking = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "barcode.viewfinder")
                        .font(.system(size: 18))
                    Text("Track from Barcode")
                }
            }
            .buttonStyle(SleekButtonStyle())
            
            Button {
                showFoodSelection.toggle()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "list.bullet.circle.fill")
                        .font(.system(size: 18))
                    Text("Select Food to Track")
                }
            }
            .buttonStyle(SleekButtonStyle())
            
            Button {
                showQuickTracking.toggle()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 18))
                    Text("Quick Track")
                }
            }
            .buttonStyle(SleekButtonStyle())
        }
    }
}

// MARK: - History Tab
struct HistoryTab: View {
    @ObservedObject var viewModel: MacroTrackerViewModel
    @ObservedObject var foodModel: FoodModel
    @Binding var showEditGoals: Bool
    @Binding var showingClearDailyMacrosAlert: Bool
    @Binding var showingClearHistoryMacrosAlert: Bool
    @Binding var showGoalWizard: Bool

    var body: some View {
        VStack(spacing: 24) {
            // History Section
            SectionCard(title: "History") {
                NavigationLink(destination: FoodLogView(viewModel: viewModel)) {
                    HStack(spacing: 12) {
                        Image(systemName: "list.clipboard.fill")
                            .font(.system(size: 18))
                    Text("View Foods Eaten Today")
                    }
                }
                .buttonStyle(SleekButtonStyle())
                
                NavigationLink(destination: MacroHistoryView(viewModel: viewModel)) {
                    HStack(spacing: 12) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 18))
                    Text("View Macro History")
                    }
                }
                .buttonStyle(SleekButtonStyle())
                
                Button {
                    showingClearDailyMacrosAlert = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 18))
                        Text("Clear Daily Macros")
                    }
                }
                .buttonStyle(SleekButtonStyle(isDestructive: true))
                .alert("Are you sure?", isPresented: $showingClearDailyMacrosAlert) {
                    Button("Clear", role: .destructive) {
                        viewModel.resetMacros()
                    }
                    Button("Cancel", role: .cancel) {}
                }

                Button {
                    showingClearHistoryMacrosAlert = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "trash")
                            .font(.system(size: 18))
                        Text("Clear History")
                    }
                }
                .buttonStyle(SleekButtonStyle(isDestructive: true))
                .alert("Are you sure?", isPresented: $showingClearHistoryMacrosAlert) {
                    Button("Clear", role: .destructive) {
                        viewModel.clearHistory()
                    }
                    Button("Cancel", role: .cancel) {}
                }
            }

            // Personal Section
            SectionCard(title: "Personal") {
                Button {
                    showEditGoals = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 18))
                        Text("Edit Macro Goals")
                    }
                }
                .buttonStyle(SleekButtonStyle())
                
                Button {
                    showGoalWizard = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 18))
                        Text("Calculate My Macros")
                    }
                }
                .buttonStyle(SleekButtonStyle())
                .sheet(isPresented: $showGoalWizard) {
                    MacroGoalWizardView(
                        calorieGoal: $viewModel.caloriesGoal,
                        proteinGoal: $viewModel.proteinGoal,
                        carbGoal: $viewModel.carbGoal,
                        fatGoal: $viewModel.fatGoal
                    )
                }
            }
            
            // Developer Section (collapsed)
            DisclosureGroup {
                VStack(spacing: 10) {
                    Button {
                    let defaults = UserDefaults.standard
                        defaults.removeObject(forKey: "macro_calorie_goal")
                        defaults.removeObject(forKey: "macro_protein_goal")
                        defaults.removeObject(forKey: "macro_carbs_goal")
                        defaults.removeObject(forKey: "macro_fats_goal")
                        viewModel.caloriesGoal = 0
                        viewModel.proteinGoal = 0
                        viewModel.carbGoal = 0
                        viewModel.fatGoal = 0
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 16))
                            Text("Reset Macro Goals")
                                .font(.system(size: 14))
                        }
                    }
                    .buttonStyle(SleekButtonStyle(isSecondary: true))
                    
                    Button {
                        foodModel.clearUserFoodDictionary()
                        foodModel.load()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "trash.circle")
                                .font(.system(size: 16))
                            Text("Delete Food Dictionary")
                                .font(.system(size: 14))
                        }
                    }
                    .buttonStyle(SleekButtonStyle(isSecondary: true))
                }
                .padding(.top, 8)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "hammer.fill")
                        .font(.system(size: 14))
                    Text("Developer Tools")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(AppTheme.textTertiary)
            }
            .accentColor(AppTheme.textTertiary)
            .padding(.horizontal, 4)
        }
    }
}

// MARK: - Main Menu
struct MainMenu: View {
    @StateObject private var viewModel = MacroTrackerViewModel()
    @StateObject private var foodModel = FoodModel()

    @State private var selectedFood: FoodItem? = nil
    @State private var selectedFoodID: UUID?
    @State private var showFoodSelection = false
    @State private var showGramsInput = false
    @State private var gramsOrServings: Double? = nil
    @State private var selectedMeasurementMode: MeasurementMode? = nil
    
    @State private var showInitialGoalPrompt = false
    @State private var showGoalWizard = false
    
    @State private var showManual = false
    @State private var showScanner = false
    
    @State private var scannedItem: FoodItem? = nil
    @State private var showScannerTracking = false
    @State private var showEditGoals = false
    
    @State private var showingClearDailyMacrosAlert = false
    @State private var showingClearHistoryMacrosAlert = false
    
    @State private var showDietPrompt = false
    @State private var pendingAction: (() -> Void)? = nil
    
    @State private var showQuickTracking = false
    
    // For creating meals from multiple foods
    @State private var showMealBuilder = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Macro Display at top
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
                .padding(.top, 8)
                
                // Tab View
                TabView {
                    ScrollView {
                        FoodDictionaryTab(
                            showManual: $showManual,
                            showScanner: $showScanner,
                            showMealBuilder: $showMealBuilder,
                            selectedFood: $selectedFood,
                            selectedFoodID: $selectedFoodID,
                            showGramsInput: $showGramsInput,
                            selectedMeasurementMode: $selectedMeasurementMode,
                            foodModel: foodModel,
                            showDietPrompt: $showDietPrompt,
                            pendingAction: $pendingAction) 
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                    }
                    .tabItem {
                        Label("Dictionary", systemImage: "book.fill")
                    }

                    ScrollView {
                        TrackFoodTab(
                            showFoodSelection: $showFoodSelection,
                            showScannerTracking: $showScannerTracking,
                            showQuickTracking: $showQuickTracking
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                    }
                    .tabItem {
                        Label("Track", systemImage: "fork.knife")
                    }

                    ScrollView {
                        HistoryTab(
                            viewModel: viewModel,
                            foodModel: foodModel,
                            showEditGoals: $showEditGoals,
                            showingClearDailyMacrosAlert: $showingClearDailyMacrosAlert,
                            showingClearHistoryMacrosAlert: $showingClearHistoryMacrosAlert,
                            showGoalWizard: $showGoalWizard
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                    }
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                }
            }
            .background(AppTheme.background.ignoresSafeArea())
            .setupNavigationAppearance()
            .setupTabBarAppearance()
            .onAppear {
                if viewModel.caloriesGoal == 0 &&
                   viewModel.proteinGoal == 0 &&
                   viewModel.carbGoal == 0 &&
                   viewModel.fatGoal == 0 {
                    showInitialGoalPrompt = true
                }
            }
            // MARK: Sheets
            .sheet(isPresented: $showManual) {
                AddFoodView(onAdd: { newFood in
                    foodModel.add(newFood)
                })
            }
            .sheet(isPresented: $showScanner) {
                BarcodeTrackingWrapperView(viewModel: foodModel)
            }
            .sheet(isPresented: $showMealBuilder) {
                MealBuilderView(foodModel: foodModel)
            }
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
                    currentMacros: (viewModel.calories, viewModel.protein, viewModel.carbs, viewModel.fats),
                    updateMacros: { _, _, _, _ in
                        let actualQuantity = gramsOrServings ?? 0.0
                        viewModel.logFood(
                            food,
                            gramsOrServings: actualQuantity,
                            mode: food.servingUnit == .grams ? .weight : .serving,
                            at: Date()
                        )
                        scannedItem = nil
                    }
                )
            }
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
                            currentMacros: (viewModel.calories, viewModel.protein, viewModel.carbs, viewModel.fats),
                            updateMacros: { _, _, _, _ in
                                let actualQuantity = gramsOrServings ?? 0.0
                                viewModel.logFood(food,
                                                  gramsOrServings: actualQuantity,
                                                  mode: mode,
                                                  at: Date())
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
            .sheet(isPresented: $showEditGoals) {
                EditGoalsView(
                    calorieGoal: $viewModel.caloriesGoal,
                    proteinGoal: $viewModel.proteinGoal,
                    carbGoal: $viewModel.carbGoal,
                    fatGoal: $viewModel.fatGoal
                )
            }
            .sheet(isPresented: $showInitialGoalPrompt) {
                InitialGoalPromptView(
                    showInitialGoalPrompt: $showInitialGoalPrompt,
                    showEditGoals: $showEditGoals,
                    showGoalWizard: $showGoalWizard,
                    viewModel: viewModel
                )
            }
            .sheet(isPresented: $showGoalWizard) {
                MacroGoalWizardView(
                    calorieGoal: $viewModel.caloriesGoal,
                    proteinGoal: $viewModel.proteinGoal,
                    carbGoal: $viewModel.carbGoal,
                    fatGoal: $viewModel.fatGoal
                )
            }
            .sheet(isPresented: $showQuickTracking) {
                QuickMacroTrackView { quickFood in
                    viewModel.logFood(quickFood, gramsOrServings: 1.0, mode: .serving, at: Date())
                }
            }
        }
    }
}

// MARK: - Initial Goal Prompt View
struct InitialGoalPromptView: View {
    @Binding var showInitialGoalPrompt: Bool
    @Binding var showEditGoals: Bool
    @Binding var showGoalWizard: Bool
    @ObservedObject var viewModel: MacroTrackerViewModel
    
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "target")
                        .font(.system(size: 48, weight: .light))
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Text("Set Your Goals")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Text("Set your calorie and macro goals to track your progress with the rings.")
                        .font(.system(size: 15))
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .padding(.top, 40)
                
                // Buttons
                VStack(spacing: 12) {
                    Button {
                        showInitialGoalPrompt = false
                        showEditGoals = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 18))
                            Text("Set My Goals")
                        }
                    }
                    .buttonStyle(SleekButtonStyle())
                    
                    Button {
                        showInitialGoalPrompt = false
                        showGoalWizard = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 18))
                            Text("Calculate for Me")
                        }
                    }
                    .buttonStyle(SleekButtonStyle())
                    
                    Button {
                        viewModel.caloriesGoal = 2000
                        viewModel.proteinGoal = 150
                        viewModel.carbGoal = 250
                        viewModel.fatGoal = 70
                        showInitialGoalPrompt = false
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 18))
                            Text("Use Default Goals")
                        }
                    }
                    .buttonStyle(SleekButtonStyle(isSecondary: true))
                }
                .padding(.horizontal, 24)
                
                Spacer()
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}
