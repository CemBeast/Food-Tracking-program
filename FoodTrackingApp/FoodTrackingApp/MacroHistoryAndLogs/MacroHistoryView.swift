//
//  MacroHistoryView.swift
//  FoodTrackingApp
//
//  Created by Cem Beyenal on 12/25/24.
//

import SwiftUI

struct MacroHistoryView: View {
    @ObservedObject var viewModel: MacroTrackerViewModel
    @ObservedObject var foodModel: FoodModel

    var body: some View {
        let (avgCal, avgProtein, avgCarb, avgFat) = getAvgMacros()

        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            List {
                VStack(spacing: 16.scaled) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4.scaled) {
                            Text("DAILY AVERAGE")
                                .font(.system(size: 11.scaled, weight: .bold))
                                .tracking(1.2.scaled)
                                .foregroundColor(AppTheme.textTertiary)

                            Text("Based on \(viewModel.history.count) day\(viewModel.history.count == 1 ? "" : "s")")
                                .font(.system(size: 13.scaled))
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        Spacer()
                    }

                    HStack(spacing: 12.scaled) {
                        AverageMacroPill(value: "\(avgCal)", label: "cal", color: AppTheme.calorieColor)
                        AverageMacroPill(value: String(format: "%.0f", avgProtein), label: "protein", color: AppTheme.proteinColor)
                        AverageMacroPill(value: String(format: "%.0f", avgCarb), label: "carbs", color: AppTheme.carbColor)
                        AverageMacroPill(value: String(format: "%.0f", avgFat), label: "fats", color: AppTheme.fatColor)
                    }
                }
                .padding(20.scaled)
                .background(
                    RoundedRectangle(cornerRadius: 16.scaled)
                        .fill(AppTheme.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16.scaled)
                                .stroke(AppTheme.border, lineWidth: 1)
                        )
                )
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 16.scaled, leading: 20.scaled, bottom: 8.scaled, trailing: 20.scaled))

                if viewModel.history.isEmpty {
                    VStack(spacing: 16.scaled) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 48.scaled, weight: .light))
                            .foregroundColor(AppTheme.textTertiary)

                        Text("No History Yet")
                            .font(.system(size: 18.scaled, weight: .semibold))
                            .foregroundColor(AppTheme.textPrimary)

                        Text("Your daily macro totals will appear here")
                            .font(.system(size: 14.scaled))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60.scaled)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } else {
                    ForEach(viewModel.history.sorted(by: { $0.date > $1.date })) { entry in
                        ZStack {
                            HistoryDayRow(entry: entry)
                            NavigationLink {
                                FoodLogViewForDate(entries: entry.foodsEaten, foodModel: foodModel)
                            } label: {
                                EmptyView()
                            }
                            .opacity(0)
                            .buttonStyle(.plain)
                        }
                        .contentShape(Rectangle())
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                viewModel.deleteHistoryEntry(entry)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 6.scaled, leading: 20.scaled, bottom: 6.scaled, trailing: 20.scaled))
                    }
                }

                Spacer(minLength: 40.scaled)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.large)
    }

    func getAvgMacros() -> (Int, Double, Double, Double) {
        var totalCal = 0
        var totalProtein = 0.0, totalCarb = 0.0, totalFats = 0.0
        if viewModel.history.isEmpty { return (0, 0, 0, 0) }
        for entry in viewModel.history {
            totalCal += entry.calories
            totalProtein += entry.protein
            totalCarb += entry.carbs
            totalFats += entry.fats
        }
        let count = Double(viewModel.history.count)
        return (
            totalCal / viewModel.history.count,
            totalProtein / count,
            totalCarb / count,
            totalFats / count
        )
    }
}

// MARK: - Average Macro Pill
struct AverageMacroPill: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6.scaled) {
            Text(value)
                .font(.system(size: 18.scaled, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 10.scaled, weight: .medium))
                .foregroundColor(color.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12.scaled)
        .background(
            RoundedRectangle(cornerRadius: 12.scaled)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - History Day Row
struct HistoryDayRow: View {
    let entry: MacroHistoryEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12.scaled) {
            HStack {
                Text(entry.date.historyDayLabel)
                    .font(.system(size: 16.scaled, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Spacer()
                
                // Image(systemName: "chevron.right")
                //     .font(.system(size: 12, weight: .semibold))
                //     .foregroundColor(AppTheme.textTertiary)
            }
            
            HStack(spacing: 8.scaled) {
                MacroPill(value: "\(entry.calories)", label: "cal", color: AppTheme.calorieColor)
                MacroPill(value: "\(Int(entry.protein.rounded()))", label: "P", color: AppTheme.proteinColor)
                MacroPill(value: "\(Int(entry.carbs.rounded()))", label: "C", color: AppTheme.carbColor)
                MacroPill(value: "\(Int(entry.fats.rounded()))", label: "F", color: AppTheme.fatColor)
            }
        }
        .padding(16.scaled)
        .background(
            RoundedRectangle(cornerRadius: 14.scaled)
                .fill(AppTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 14.scaled)
                        .stroke(AppTheme.border, lineWidth: 1)
                )
        )
    }
}

// MARK: - Date label
extension Date {
    /// "Nov 17, 2026 · Monday"
    var historyDayLabel: String {
        formatted(date: .abbreviated, time: .omitted) + " · " + formatted(.dateTime.weekday(.wide))
    }
}
