//
//  FoodMLPredictor.swift
//  FoodTrackingApp
//
//  Created by Cem Beyenal on 2/2/26.
//


import Foundation
import CoreML
import UIKit
import CoreVideo

final class FoodMLPredictor {
    private let labels: [String]

    init() {
        self.labels = Self.loadLabels()
    }

    func predict(uiImage: UIImage) throws -> (label: String, confidence: Double) {
        guard !labels.isEmpty else {
            throw NSError(domain: "FoodMLPredictor", code: 10,
                          userInfo: [NSLocalizedDescriptionKey: "classes.txt missing/empty"])
        }

        guard let pixelBuffer = uiImage.toCVPixelBuffer(width: 224, height: 224) else {
            throw NSError(domain: "FoodMLPredictor", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to create CVPixelBuffer"])
        }

        let config = MLModelConfiguration()
        config.computeUnits = .all
        let model = try FoodClassifier(configuration: config)

        // If Xcode generated prediction(image:) change this line accordingly
        let output = try model.prediction(input: pixelBuffer)

        // Your output is var_331: MLMultiArray (1 x 101)
        let logits = output.var_331

        let idx = Self.argmax(logits)
        let probs = Self.softmax(logits)
        let conf = (idx < probs.count) ? probs[idx] : 0.0

        let name = (idx < labels.count) ? labels[idx] : "class_\(idx)"
        return (name, conf)
    }

    // MARK: - Labels

    private static func loadLabels() -> [String] {
        guard let url = Bundle.main.url(forResource: "classes", withExtension: "txt"),
              let text = try? String(contentsOf: url) else {
            return []
        }
        return text
            .split(whereSeparator: \.isNewline)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    // MARK: - Math

    private static func argmax(_ a: MLMultiArray) -> Int {
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

    private static func softmax(_ a: MLMultiArray) -> [Double] {
        var maxVal = -Double.infinity
        for i in 0..<a.count { maxVal = max(maxVal, a[i].doubleValue) }

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
}

// MARK: - UIImage -> CVPixelBuffer

extension UIImage {
    func toCVPixelBuffer(width: Int = 224, height: Int = 224) -> CVPixelBuffer? {
        let attrs: [CFString: Any] = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true
        ]

        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32BGRA,
            attrs as CFDictionary,
            &pixelBuffer
        )
        guard status == kCVReturnSuccess, let pb = pixelBuffer else { return nil }

        CVPixelBufferLockBaseAddress(pb, [])
        defer { CVPixelBufferUnlockBaseAddress(pb, []) }

        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(pb),
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(pb),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
        ) else { return nil }

        UIGraphicsPushContext(context)
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1.0, y: -1.0)
        self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        UIGraphicsPopContext()

        return pb
    }
}