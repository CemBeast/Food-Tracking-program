//
//  ModelImageTestView.swift
//  FoodTrackingApp
//
//  Created by Cem Beyenal on 2/2/26.
//

import SwiftUI
import PhotosUI
import CoreML
import UIKit
import CoreVideo

// MARK: - Load labels from classes.txt in app bundle

func loadLabels() -> [String] {
    guard let url = Bundle.main.url(forResource: "classes", withExtension: "txt"),
          let text = try? String(contentsOf: url) else {
        return []
    }
    return text
        .split(whereSeparator: \.isNewline)
        .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
}

// MARK: - Math helpers

func argmax(_ a: MLMultiArray) -> Int {
    var bestIdx = 0
    var bestVal = -Double.infinity
    for i in 0..<a.count {
        let v = a[i].doubleValue
        if v > bestVal {
            bestVal = v
            bestIdx = i
        }
    }
    return bestIdx
}

func softmax(_ a: MLMultiArray) -> [Double] {
    // Numerical stability: subtract max
    var maxVal = -Double.infinity
    for i in 0..<a.count {
        maxVal = max(maxVal, a[i].doubleValue)
    }

    var exps = Array(repeating: 0.0, count: a.count)
    var sum = 0.0
    for i in 0..<a.count {
        let e = Foundation.exp(a[i].doubleValue - maxVal)
        exps[i] = e
        sum += e
    }
    if sum == 0 { return exps }
    return exps.map { $0 / sum }
}

// MARK: - SwiftUI test view

struct ModelImageTestView: View {
    @State private var status = "Tap to pick image + predict"
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedUIImage: UIImage? = nil
    @State private var labels: [String] = []

    var body: some View {
        VStack(spacing: 16) {
            if let img = selectedUIImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 280)
                    .cornerRadius(12)
            }

            PhotosPicker(selection: $selectedItem, matching: .images) {
                Text(status)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.blue.opacity(0.15))
                    .cornerRadius(12)
            }
            .onChange(of: selectedItem) { newItem in
                guard let newItem else { return }
                Task { await predictFromPickerItem(newItem) }
            }
        }
        .padding()
        .onAppear {
            labels = loadLabels()
            if labels.isEmpty {
                status = "⚠️ classes.txt missing/empty"
            } else {
                status = "Tap to pick image + predict"
            }
        }
    }

    private func predictFromPickerItem(_ item: PhotosPickerItem) async {
        do {
            await MainActor.run { status = "Loading image..." }

            guard let data = try await item.loadTransferable(type: Data.self),
                  let uiImage = UIImage(data: data) else {
                await MainActor.run { status = "❌ Could not load image" }
                return
            }

            await MainActor.run {
                self.selectedUIImage = uiImage
                self.status = "Running model..."
            }

            let (label, confidence) = try runCoreMLPrediction(uiImage: uiImage)

            await MainActor.run {
                let pct = Int((confidence * 100).rounded())
                self.status = "✅ \(label) (\(pct)%)"
            }
        } catch {
            await MainActor.run {
                self.status = "❌ Error: \(error.localizedDescription)"
            }
        }
    }

    private func runCoreMLPrediction(uiImage: UIImage) throws -> (String, Double) {
        guard !labels.isEmpty else {
            throw NSError(domain: "CoreMLTest", code: 10,
                          userInfo: [NSLocalizedDescriptionKey: "classes.txt not loaded"])
        }

        guard let pixelBuffer = uiImage.toCVPixelBuffer(width: 224, height: 224) else {
            throw NSError(domain: "CoreMLTest", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to create CVPixelBuffer"])
        }

        let config = MLModelConfiguration()
        config.computeUnits = .all
        let model = try FoodClassifier(configuration: config)

        // IMPORTANT:
        // Use whatever Xcode generated. Most likely:
        //   let output = try model.prediction(input: pixelBuffer)
        // If yours differs, change this one line.
        let output = try model.prediction(input: pixelBuffer)

        // Your model output is: var_331 (1 x 101 Float32)
        let logits = output.var_331

        let idx = argmax(logits)
        let probs = softmax(logits)
        let conf = (idx < probs.count) ? probs[idx] : 0.0

        let label = (idx < labels.count) ? labels[idx] : "class_\(idx)"
        return (label, conf)
    }
}
