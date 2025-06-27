//
//  MacroHistoryView.swift
//  FoodTrackingApp
//
//  Created by Cem Beyenal on 12/25/24.
//

import SwiftUI

struct MacroHistoryView: View {
    @ObservedObject var viewModel: MacroTrackerViewModel

    var body: some View {
        let (avgCal, avgProtein, avgCarb, avgFat) = getAvgMacros()

        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Average Macros")
                        .font(.headline)
                        .foregroundColor(Color("TextPrimary"))

                    GeometryReader { geometry in
                        let columnWidth = geometry.size.width / 4
                        HStack(spacing: 0) {
                            macroColumn(title: "Calories", value: "\(avgCal)", width: columnWidth, color: .red)
                            macroColumn(title: "Protein", value: String(format: "%.1f g", avgProtein), width: columnWidth, color: .yellow)
                            macroColumn(title: "Carbs", value: String(format: "%.1f g", avgCarb), width: columnWidth, color: .green)
                            macroColumn(title: "Fats", value: String(format: "%.1f g", avgFat), width: columnWidth, color: .purple)
                        }
                    }
                    .frame(height: 60)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color("CardBackground")))
                .shadow(radius: 1)
            }

            Section {
                ForEach(viewModel.history.sorted(by: { $0.date > $1.date })) { entry in
                    NavigationLink {
                        FoodLogViewForDate(entries: entry.foodsEaten)
                    } label: {
                        VStack(alignment: .leading) {
                            Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.headline)
                                .foregroundColor(Color("TextPrimary"))
                            Text(
                                "Calories: \(entry.calories), " +
                                "Protein: \(Int(entry.protein.rounded()))g, " +
                                "Carbs: \(Int(entry.carbs.rounded()))g, " +
                                "Fats: \(Int(entry.fats.rounded()))g"
                            )
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("History")
    }

    func macroColumn(title: String, value: String, width: CGFloat, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(color)
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
        .frame(width: width)
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
