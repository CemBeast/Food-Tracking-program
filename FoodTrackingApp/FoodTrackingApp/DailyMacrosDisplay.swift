//
//  DailyMacrosDisplay.swift
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
    @State private var animateRings = false

    var body: some View {
        VStack(spacing: 16) {
            // Toggle Label
            HStack {
                Spacer()
                Text(showConsumed ? "CONSUMED" : "REMAINING / OVERFLOW")
                    .font(.system(size: 11, weight: .bold, design: .default))
                    .tracking(1.5)
                    .foregroundColor(AppTheme.textTertiary)
                Spacer()
            }
            
            // Ring Meters
            HStack(spacing: 20) {
                ringMeter(
                    percent: calorieGoal == 0 ? 0 : Double(calories) / Double(calorieGoal),
                    color: AppTheme.calorieColor,
                    label: "Calories",
                    value: "\(Int(displayedValue(for: calories, goal: calorieGoal)))"
                )
                ringMeter(
                    percent: proteinGoal == 0 ? 0 : protein / proteinGoal,
                    color: AppTheme.proteinColor,
                    label: "Protein",
                    value: "\(Int(displayedValue(for: protein, goal: proteinGoal)))g"
                )
                ringMeter(
                    percent: carbGoal == 0 ? 0 : carbs / carbGoal,
                    color: AppTheme.carbColor,
                    label: "Carbs",
                    value: "\(Int(displayedValue(for: carbs, goal: carbGoal)))g"
                )
                ringMeter(
                    percent: fatGoal == 0 ? 0 : fats / fatGoal,
                    color: AppTheme.fatColor,
                    label: "Fats",
                    value: "\(Int(displayedValue(for: fats, goal: fatGoal)))g"
                )
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(AppTheme.border, lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.25)) {
                showConsumed.toggle()
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animateRings = true
            }
        }
    }

    func displayedValue(for value: Double, goal: Double) -> Double {
        return showConsumed ? value : (goal - value)
    }

    func displayedValue(for value: Int, goal: Int) -> Double {
        return showConsumed ? Double(value) : Double(goal - value)
    }

    func ringMeter(percent: Double, color: Color, label: String, value: String) -> some View {
        let clamped = min(max(percent, 0), 1)
        let overflow = min(max(percent - 1, 0), 1)
        let animatedPercent = animateRings ? clamped : 0
        let animatedOverflow = animateRings ? overflow : 0
        let overflowColor = Color(red: 0.95, green: 0.35, blue: 0.15)

        return VStack(spacing: 8) {
            ZStack {
                // Overflow ring (outside)
                Circle()
                    .trim(from: 0, to: animatedOverflow)
                    .stroke(
                        overflowColor,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.8), value: animatedOverflow)
                    .frame(width: 64, height: 64)

                // Background ring
                Circle()
                    .stroke(color.opacity(0.15), lineWidth: 6)
                    .frame(width: 56, height: 56)

                // Progress ring
                Circle()
                    .trim(from: 0, to: animatedPercent)
                    .stroke(
                        color,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.8), value: animatedPercent)
                    .frame(width: 56, height: 56)
                
                // Value in center
                Text(value)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
            }
            .frame(width: 64, height: 64)

            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(AppTheme.textSecondary)
        }
    }
}
