//
//  TipsAndTricksView.swift
//  FoodTrackingApp
//

import SwiftUI

struct TipsAndTricksView: View {
    @Environment(\.dismiss) private var dismiss

    private struct Tip: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let body: String
    }

    private let tips: [Tip] = [
        Tip(icon: "target",
            title: "Set Your Macro Goals",
            body: "Head to Settings to enter your macro goals manually, or tap Calculate My Macros to get recommended targets based on your current age, height, weight, and goals."),
        Tip(icon: "book.fill",
            title: "Build Your Food Dictionary",
            body: "Add foods manually, scan barcodes, or look them up in the USDA database to grow your personal library. This app runs mainly on your food dictionary, so it's important to fill it with foods you eat consistently."),
        Tip(icon: "bolt.fill",
            title: "Quick Track Frequent Foods",
            body: "Use Quick Track to quickly log any food or drink by entering its macros. Use Quick Track Meal to log a meal you've already saved to your dictionary. This is especially useful if you eat the same meals every day and have already added them."),
        Tip(icon: "square.stack.3d.up.fill",
            title: "Create Reusable Meals",
            body: "Combine multiple foods into a single meal template so you can log a full plate at once. This greatly reduces repetition: instead of tracking many individual foods every time, you save them as one meal and track it in a single step. For example, rather than logging 2 eggs, 1 cup of milk, and 200 grams of tomatoes each morning, you can create a meal called 'Breakfast' and simply track 'Breakfast' every day."),
        Tip(icon: "chart.line.uptrend.xyaxis",
            title: "Review Your History",
            body: "The History tab has two views. Tap View Foods Eaten Today to see everything you've logged today; from there, tap any food to edit its quantity, and your macros will update automatically. Tap View Macro History to scroll through your logs from previous days and see what you ate."),
    ]

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: 12) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 44, weight: .light))
                        .foregroundColor(AppTheme.textPrimary)

                    Text("Tips & Tricks")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)

                    Text("A quick tour to help you get the most out of the app.")
                        .font(.system(size: 15))
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .padding(.top, 32)
                .padding(.bottom, 24)

                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(tips) { tip in
                            HStack(alignment: .top, spacing: 14) {
                                Image(systemName: tip.icon)
                                    .font(.system(size: 20))
                                    .foregroundColor(AppTheme.textPrimary)
                                    .frame(width: 28, alignment: .center)
                                    .padding(.top, 2)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(tip.title)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(AppTheme.textPrimary)
                                    Text(tip.body)
                                        .font(.system(size: 14))
                                        .foregroundColor(AppTheme.textSecondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Spacer(minLength: 0)
                            }
                            .cardStyle()
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                }

                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                        Text("Got it")
                    }
                }
                .buttonStyle(SleekButtonStyle())
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
        }
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    TipsAndTricksView()
}
