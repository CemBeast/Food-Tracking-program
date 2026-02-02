//
//  ConfirmFoodNameAndGramsView.swift
//  FoodTrackingApp
//
//  Created by Cem Beyenal on 2/2/26.
//


import SwiftUI
import UIKit

struct FoodPredictionResult {
    let image: UIImage
    let predictedName: String
    let confidence: Double   // 0...1
}

struct FoodConfirmedInput {
    let image: UIImage
    let foodName: String
    let grams: Double
    let predictedName: String
    let confidence: Double
}

struct ConfirmFoodNameAndGramsView: View {
    let result: FoodPredictionResult
    let onConfirm: (FoodConfirmedInput) -> Void

    @State private var foodName: String
    @State private var gramsText: String = ""

    @Environment(\.dismiss) private var dismiss

    init(result: FoodPredictionResult, onConfirm: @escaping (FoodConfirmedInput) -> Void) {
        self.result = result
        self.onConfirm = onConfirm
        _foodName = State(initialValue: result.predictedName)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {

                Image(uiImage: result.image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 260)
                    .cornerRadius(14)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Prediction")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Text("\(result.predictedName) • \(Int((result.confidence * 100).rounded()))%")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider()

                VStack(alignment: .leading, spacing: 10) {
                    Text("Is this correct? Edit if needed")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    TextField("Food name", text: $foodName)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .textFieldStyle(.roundedBorder)

                    Text("How many grams did you eat?")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    TextField("e.g. 180", text: $gramsText)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                }

                Button {
                    let grams = Double(gramsText) ?? 0
                    let cleanedName = foodName.trimmingCharacters(in: .whitespacesAndNewlines)

                    let confirmed = FoodConfirmedInput(
                        image: result.image,
                        foodName: cleanedName,
                        grams: grams,
                        predictedName: result.predictedName,
                        confidence: result.confidence
                    )

                    onConfirm(confirmed)
                    dismiss()
                } label: {
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SleekButtonStyle())
                .disabled(!canContinue)
            }
            .padding()
        }
        .navigationTitle("Confirm Food")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var canContinue: Bool {
        let nameOK = !foodName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let grams = Double(gramsText) ?? 0
        return nameOK && grams > 0
    }
}
