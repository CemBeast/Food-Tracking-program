//
//  ScannerTrackingViewController.swift
//  FoodTrackingApp
//
//  Created by Cem Beyenal on 5/20/25.
//
import SwiftUI
import AVFoundation

class ScannerTrackingViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var onScanned: ((FoodItem) -> Void)?

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
        if let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
           let code = metadataObject.stringValue {
            captureSession.stopRunning()
            lookupAndReturnFood(barcode: code)
        }
    }

    func lookupAndReturnFood(barcode: String) {
        let urlString = "https://world.openfoodfacts.org/api/v0/product/\(barcode).json"
        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let product = json["product"] as? [String: Any],
                  let name = product["product_name"] as? String,
                  let nutriments = product["nutriments"] as? [String: Any] else { return }

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

            // Print serving string
            print("🔍 Serving size string: \(product["serving_size"] ?? "N/A")")
            print("📦 Nutrients per serving:")
            print("  - Calories: \(nutriments["energy-kcal_serving"] ?? "N/A")")
            print("  - Energy (kJ): \(nutriments["energy_serving"] ?? "N/A")")
            print("  - Protein (g): \(nutriments["proteins_serving"] ?? "N/A")")
            print("  - Carbs (g): \(nutriments["carbohydrates_serving"] ?? "N/A")")
            print("  - Fat (g): \(nutriments["fat_serving"] ?? "N/A")")

            print("📊 Nutrients per 100g:")
            print("  - Calories (kcal_100g): \(nutriments["energy-kcal_100g"] ?? "N/A")")
            print("  - Protein (g): \(nutriments["proteins_100g"] ?? "N/A")")
            print("  - Carbs (g): \(nutriments["carbohydrates_100g"] ?? "N/A")")
            print("  - Fat (g): \(nutriments["fat_100g"] ?? "N/A")")

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
                name: name,
                weightInGrams: servingAmount ?? 100,
                servings: 1,
                calories: calories,
                protein: protein,
                carbs: carbs,
                fats: fats,
                servingUnit: servingUnit
            )

            DispatchQueue.main.async {
                self.onScanned?(item)
                //self.dismiss(animated: true)
            }
        }.resume()
    }
}
