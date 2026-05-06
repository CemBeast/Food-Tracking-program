//
//  ScannerTrackingViewController.swift
//  FoodTrackingApp
//
//  Created by Cem Beyenal on 5/20/25.
//
import SwiftUI
import AVFoundation

enum BarcodeLookupError: Error {
    case network
    case notFound
    case missingNutrition

    var message: String {
        switch self {
        case .network:
            return "Couldn't reach the food database. Check your connection and try again."
        case .notFound:
            return "No product found for that barcode."
        case .missingNutrition:
            return "We found this product, but it has no nutrition info."
        }
    }
}

class ScannerTrackingViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var onScanned: ((FoodItem) -> Void)?
    var onError: ((BarcodeLookupError) -> Void)?
    var onLookupStarted: (() -> Void)?

    private var isProcessing = false
    private var lastScannedCode: String?
    private var lastScannedAt: Date?
    private static let rescanInterval: TimeInterval = 3.0

    private lazy var lookupSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 15
        return URLSession(configuration: config)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        captureSession = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        do {
            let videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            if captureSession.canAddInput(videoInput) { captureSession.addInput(videoInput) }
        } catch { return }

        let metadataOutput = AVCaptureMetadataOutput()
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.ean8, .ean13]
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if captureSession.isRunning { captureSession.stopRunning() }
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        guard !isProcessing,
              let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let code = metadataObject.stringValue else { return }

        if let last = lastScannedCode, last == code,
           let lastAt = lastScannedAt,
           Date().timeIntervalSince(lastAt) < Self.rescanInterval {
            return
        }

        lastScannedCode = code
        lastScannedAt = Date()
        isProcessing = true
        onLookupStarted?()
        lookupAndReturnFood(barcode: code)
    }

    func lookupAndReturnFood(barcode: String) {
        let urlString = "https://world.openfoodfacts.org/api/v0/product/\(barcode).json"
        guard let url = URL(string: urlString) else {
            finish(error: .network)
            return
        }

        lookupSession.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self else { return }

            if error != nil {
                self.finish(error: .network)
                return
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                self.finish(error: .network)
                return
            }

            // OpenFoodFacts returns status: 0 when the product isn't in their DB.
            if let status = json["status"] as? Int, status == 0 {
                self.finish(error: .notFound)
                return
            }

            guard let product = json["product"] as? [String: Any] else {
                self.finish(error: .notFound)
                return
            }

            guard let rawName = product["product_name"] as? String,
                  !rawName.isEmpty,
                  let nutriments = product["nutriments"] as? [String: Any] else {
                self.finish(error: .missingNutrition)
                return
            }

            let servingString = product["serving_size"] as? String ?? ""

            // Extract amount and unit
            var servingAmount: Int?
            var servingUnit: ServingUnit = .grams  // default
            let pattern = #"(\d+(?:\.\d+)?)\s*(g|ml)"#
            if let match = servingString.range(of: pattern, options: .regularExpression) {
                let matchedText = String(servingString[match])
                let numberPart = matchedText
                    .components(separatedBy: CharacterSet.letters)
                    .joined()
                    .trimmingCharacters(in: .whitespaces)

                if let value = Double(numberPart) {
                    servingAmount = Int(value)
                    if matchedText.contains("ml") {
                        servingUnit = .milliliters
                    } else if matchedText.contains("g") {
                        servingUnit = .grams
                    }
                }
            }

            let useServingBased = (servingAmount != nil)

            // Macronutrient extraction
            let calories: Int = {
                if useServingBased {
                    if let kcal = nutriments["energy-kcal_serving"] as? Int {
                        return kcal
                    } else if let kj = nutriments["energy_serving"] as? Double {
                        return Int(kj / 4.184)
                    }
                }
                return Int(nutriments["energy-kcal_100g"] as? Double ?? 0)
            }()

            let protein = useServingBased
                ? (nutriments["proteins_serving"] as? Double ?? 0)
                : (nutriments["proteins_100g"] as? Double ?? 0)

            let carbs = useServingBased
                ? (nutriments["carbohydrates_serving"] as? Double ?? 0)
                : (nutriments["carbohydrates_100g"] as? Double ?? 0)

            let fats = useServingBased
                ? (nutriments["fat_serving"] as? Double ?? 0)
                : (nutriments["fat_100g"] as? Double ?? 0)

            let item = FoodItem(
                name: rawName,
                weightInGrams: servingAmount ?? 100,
                servings: 1,
                calories: calories,
                protein: protein,
                carbs: carbs,
                fats: fats,
                servingUnit: servingUnit
            )

            DispatchQueue.main.async {
                self.isProcessing = false
                self.onScanned?(item)
            }
        }.resume()
    }

    private func finish(error: BarcodeLookupError) {
        DispatchQueue.main.async {
            self.isProcessing = false
            self.onError?(error)
        }
    }
}
