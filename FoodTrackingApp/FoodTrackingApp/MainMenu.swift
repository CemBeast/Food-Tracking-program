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
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Food Macros Display
                FoodMacrosDisplay(calories: calories, protein: protein, carbs: carbs, fats: fats)
                
                Spacer()
                
                NavigationLink(destination: DictionaryView()) {
                        Text("View Food Dictionary")
                        .buttonStyle(CustomButtonStyle())
                    }
                Button(action: {
                                    // Trigger logic to let the user select a food item
                                    // This will navigate to the DictionaryView
                                    // (Already handled via NavigationLink)
                                }) {
                                    Text("Select Food to Track")
                                        .buttonStyle(CustomButtonStyle())
                                }
                                
                                // Display selected food macros if available
                                if let food = selectedFood {
                                    FoodMacrosDisplay(
                                        calories: food.calories,
                                        protein: food.protein,
                                        carbs: food.carbs,
                                        fats: food.fats
                                    )
                                }
                       // Add more NavigationLinks for other options
                Spacer()
                   }
                   .navigationTitle("Food Tracking Menu")
               }
    }
    
    let menuOptions = [
        "Enter food item",
        "Print list of food ate today with macros",
        "Print total macros",
        "Add food to dictionary",
        "Print food dictionary",
        "Save Dictionary file",
        "Write food to log file",
        "Edit Food",
        "Enter quick food"
    ]
}

struct MainMenuPreviews: PreviewProvider {
    static var previews: some View {
        MainMenu()
    }
}

