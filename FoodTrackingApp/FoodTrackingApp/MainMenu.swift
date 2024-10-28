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
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                NavigationLink(destination: DictionaryView()) {
                        Text("View Food Dictionary")
                        .buttonStyle(CustomButtonStyle())
                    }
                       // Add more NavigationLinks for other options
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

