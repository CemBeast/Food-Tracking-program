//
//  RemainingMacrosCard.swift
//  FoodTrackingApp
//
//  Created by Cem Beyenal on 5/27/25.
//
import SwiftUI

struct DailyMacrosDisplay: View {
    var calories: Int
    var protein: Double
    var carbs: Double
    var fats: Double

    var calorieGoal: Int
    var proteinGoal: Double
    var carbGoal: Double
    var fatGoal: Double

    @State private var showConsumed = true
    @State private var garbage = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(showConsumed ? "Macros Consumed" : "Macros Left")
                .font(.title2.bold())
                .foregroundColor(Color("TextPrimary"))
                .padding(.horizontal)
                .frame(maxWidth: .infinity, alignment: .center)

            HStack(spacing: 16) {
                ringMeter(
                    percent: calorieGoal == 0 ? 0 : Double(calories) / Double(calorieGoal),
                    color: .red,
                    label: "Calories",
                    value: "\(Int(displayedValue(for: calories, goal: calorieGoal)))"
                )
                ringMeter(
                    percent: proteinGoal == 0 ? 0 : protein / proteinGoal,
                    color: .yellow,
                    label: "Protein",
                    value: "\(Int(displayedValue(for: protein, goal: proteinGoal)))g"
                )
                ringMeter(
                    percent: carbGoal == 0 ? 0 : carbs / carbGoal,
                    color: .green,
                    label: "Carbs",
                    value: "\(Int(displayedValue(for: carbs, goal: carbGoal)))g"
                )
                ringMeter(
                    percent: fatGoal == 0 ? 0 : fats / fatGoal,
                    color: .purple,
                    label: "Fats",
                    value: "\(Int(displayedValue(for: fats, goal: fatGoal)))g"
                )
            }
            .padding(.horizontal)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color("CardBackground"))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
        .padding(.horizontal)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.3)) {
                showConsumed.toggle()
            }
        }
    }

    func displayedValue(for value: Double, goal: Double) -> Double {
        return showConsumed ? value : max(goal - value, 0)
    }

    func displayedValue(for value: Int, goal: Int) -> Double {
        return showConsumed ? Double(value) : Double(max(goal - value, 0))
    }

    func ringMeter(percent: Double, color: Color, label: String, value: String) -> some View {
        let clamped = min(max(percent, 0), 1)

        return VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 8)

                Circle()
                    .trim(from: 0, to: clamped)
                    .stroke(
                        color,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: color.opacity(0.6), radius: 4, x: 0, y: 2)
            }
            .frame(width: 60, height: 60)

            VStack(spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(Color("TextPrimary").opacity(0.8))
                Text(value)
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(Color("TextPrimary"))
            }
        }
    }
}
