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
            body: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Head to Settings to enter goals manually or let the wizard calculate them for you."),
        Tip(icon: "book.fill",
            title: "Build Your Food Dictionary",
            body: "Lorem ipsum dolor sit amet. Add foods manually, scan barcodes, or look them up in the USDA database to grow your personal library."),
        Tip(icon: "bolt.fill",
            title: "Quick Track Frequent Foods",
            body: "Lorem ipsum dolor sit amet. Use Quick Track on the Track tab to log meals you eat often in just a couple of taps."),
        Tip(icon: "square.stack.3d.up.fill",
            title: "Create Reusable Meals",
            body: "Lorem ipsum dolor sit amet. Combine multiple foods into a single meal template so you can log a full plate at once."),
        Tip(icon: "chart.line.uptrend.xyaxis",
            title: "Review Your History",
            body: "Lorem ipsum dolor sit amet. The History tab shows what you ate today and your macro trends over time."),
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
