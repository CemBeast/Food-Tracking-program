//
//  FoodTrackingAppApp.swift
//  FoodTrackingApp
//
//  Created by Cem Beyenal on 12/23/23.
//

import SwiftUI

@main
struct FoodTrackingAppApp: App {
    init() {
        KeyboardSwipeDismiss.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
