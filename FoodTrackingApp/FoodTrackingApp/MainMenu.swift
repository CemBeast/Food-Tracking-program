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
    @StateObject private var viewModel = MacroTrackerViewModel()

    @State private var selectedFood: FoodItem? = nil
    @State private var showFoodSelection = false
    @State private var showGramsInput = false
    @State private var gramsOrServings: Int? = nil

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Food Macros Display
                FoodMacrosDisplay(
                    calories: viewModel.calories,
                    protein: viewModel.protein,
                    carbs: viewModel.carbs,
                    fats: viewModel.fats
                )

                Spacer()
                
                NavigationLink(destination: AddFoodView(onAdd: {newFood in
                    foodItems.append(newFood)
                    saveChanges()
                })) {
                    Text("➕ Add New Food")
                        .buttonStyle(CustomButtonStyle())
                }
                
                // View the food dictionary only
                NavigationLink(destination: DictionaryView(
                    selectedFood: $selectedFood,
                    showGramsInput: $showGramsInput,
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
                Button(action: {
                    let today = viewModel.formatDate(Date())
                        viewModel.saveMacros(for: today)
                        print("Macros saved for today: \(today)")
                    }) {
                    Text("Save Today's Macros")
                        .buttonStyle(CustomButtonStyle())
                }
                
                // History Button
                NavigationLink(destination: MacroHistoryView(viewModel: viewModel)) {
                    Text("View Macro History")
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

