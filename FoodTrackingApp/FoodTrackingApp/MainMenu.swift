//
//  MainMenu.swift
//  FoodTrackingApp
//
//  Created by Cem Beyenal on 10/28/24.
//
import SwiftUI


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
    @State private var calories = 0
    @State private var protein = 0.0
    @State private var carbs = 0.0
    @State private var fats = 0.0
    
    // State for selected food item
    @State private var selectedFood: FoodItem? = nil
    @State private var showFoodSelection = false
    @State private var showGramsInput = false
    @State private var gramsOrServings: Int? = nil
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Food Macros Display
                FoodMacrosDisplay(calories: calories, protein: protein, carbs: carbs, fats: fats)
                
                Spacer()
                
                NavigationLink(destination: DictionaryView(selectedFood: $selectedFood, showGramsInput: $showGramsInput, readOnly: true)) {
                        Text("View Food Dictionary")
                        .buttonStyle(CustomButtonStyle())
                    }
                Button(action: {
                                    showFoodSelection.toggle()
                                }) {
                                    Text("Select Food to Track")
                                        .buttonStyle(CustomButtonStyle())
                                }
                                
                                // Show modal for grams/servings input if a food is selected
                                .sheet(isPresented: $showFoodSelection) {
                                    DictionaryView(selectedFood: $selectedFood, showGramsInput: $showGramsInput, readOnly: false)
                                    // After food selection, show grams/servings input prompt
                                    if showGramsInput, let food = selectedFood {
                                        GramsOrServingsInput(
                                            food: food,
                                            gramsOrServings: $gramsOrServings,
                                            showGramsInput: $showGramsInput,
                                            updateMacros: { calculatedCalories, calculatedFats, calculatedProtein, calculatedCarbs in
                                                self.calories += Int(calculatedCalories)
                                                self.fats += calculatedFats
                                                self.protein += calculatedProtein
                                                self.carbs += calculatedCarbs
                                            }
                                        )
                                    }
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

