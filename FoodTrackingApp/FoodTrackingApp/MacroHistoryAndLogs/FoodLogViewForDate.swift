//
//  FoodLogViewForDate.swift
//  FoodTrackingApp
//
//  Created by Cem Beyenal on 6/3/25.
//

import SwiftUI

struct FoodLogViewForDate: View {
    let day: MacroHistoryEntry
    @ObservedObject var foodModel: FoodModel
    @State private var entryToAddToDictionary: LoggedFoodEntry?

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            List {
                header
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 16.scaled, leading: 20.scaled, bottom: 8.scaled, trailing: 20.scaled))

                if day.foodsEaten.isEmpty {
                    VStack(spacing: 16.scaled) {
                        Image(systemName: "tray")
                            .font(.system(size: 48.scaled, weight: .light))
                            .foregroundColor(AppTheme.textTertiary)

                        Text("No Foods Logged")
                            .font(.system(size: 18.scaled, weight: .semibold))
                            .foregroundColor(AppTheme.textPrimary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60.scaled)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } else {
                    ForEach(day.foodsEaten) { entry in
                        FoodLogEntryRow(entry: entry) {
                            entryToAddToDictionary = entry
                        }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 6.scaled, leading: 20.scaled, bottom: 6.scaled, trailing: 20.scaled))
                    }
                }
            }
            .listStyle(PlainListStyle())
            .scrollContentBackground(.hidden)
        }
        .addToDictionarySheet(entry: $entryToAddToDictionary, foodModel: foodModel)
        .navigationTitle("Daily Log")
        .navigationBarTitleDisplayMode(.inline)
    }

    /// Date, weekday and the day's stored totals (same numbers as the History card).
    private var header: some View {
        VStack(alignment: .leading, spacing: 16.scaled) {
            VStack(alignment: .leading, spacing: 4.scaled) {
                Text(day.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 22.scaled, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                Text(day.date.formatted(.dateTime.weekday(.wide)))
                    .font(.system(size: 14.scaled))
                    .foregroundColor(AppTheme.textSecondary)
            }

            HStack(spacing: 12.scaled) {
                AverageMacroPill(value: "\(day.calories)", label: "cal", color: AppTheme.calorieColor)
                AverageMacroPill(value: String(format: "%.0f", day.protein), label: "protein", color: AppTheme.proteinColor)
                AverageMacroPill(value: String(format: "%.0f", day.carbs), label: "carbs", color: AppTheme.carbColor)
                AverageMacroPill(value: String(format: "%.0f", day.fats), label: "fats", color: AppTheme.fatColor)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20.scaled)
        .background(
            RoundedRectangle(cornerRadius: 16.scaled)
                .fill(AppTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16.scaled)
                        .stroke(AppTheme.border, lineWidth: 1)
                )
        )
    }
}
