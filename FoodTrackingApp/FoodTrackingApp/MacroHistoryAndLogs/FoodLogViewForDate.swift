//
//  FoodLogViewForDate.swift
//  FoodTrackingApp
//
//  Created by Cem Beyenal on 6/3/25.
//

import SwiftUI

struct FoodLogViewForDate: View {
    let entries: [LoggedFoodEntry]
    @ObservedObject var foodModel: FoodModel
    @State private var entryToAddToDictionary: LoggedFoodEntry?

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            if entries.isEmpty {
                VStack(spacing: 16.scaled) {
                    Image(systemName: "tray")
                        .font(.system(size: 48.scaled, weight: .light))
                        .foregroundColor(AppTheme.textTertiary)
                    
                    Text("No Foods Logged")
                        .font(.system(size: 18.scaled, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)
                }
            } else {
                List {
                    ForEach(entries) { entry in
                        FoodLogEntryRow(entry: entry) {
                            entryToAddToDictionary = entry
                        }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 6.scaled, leading: 20.scaled, bottom: 6.scaled, trailing: 20.scaled))
                    }
                }
                .listStyle(PlainListStyle())
                .scrollContentBackground(.hidden)
            }
        }
        .addToDictionarySheet(entry: $entryToAddToDictionary, foodModel: foodModel)
        .navigationTitle("Daily Log")
        .navigationBarTitleDisplayMode(.large)
    }
}
