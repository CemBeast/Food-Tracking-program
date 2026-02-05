//
//  FoodLogViewForDate.swift
//  FoodTrackingApp
//
//  Created by Cem Beyenal on 6/3/25.
//

import SwiftUI

struct FoodLogViewForDate: View {
    let entries: [LoggedFoodEntry]

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            if entries.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "tray")
                        .font(.system(size: 48, weight: .light))
                        .foregroundColor(AppTheme.textTertiary)
                    
                    Text("No Foods Logged")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)
                }
            } else {
                List {
                    ForEach(entries) { entry in
                        FoodLogEntryRow(entry: entry)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                    }
                }
                .listStyle(PlainListStyle())
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Daily Log")
        .navigationBarTitleDisplayMode(.large)
    }
}
