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
            var servingAmount: Int? = 100
            var unit: ServingUnit = .grams
            let pattern = #"(\d+(?:\.\d+)?)\s*(g|ml)"#
            if let match = servingString.range(of: pattern, options: .regularExpression) {
                let matched = String(servingString[match])
                if matched.contains("ml") { unit = .milliliters }
                servingAmount = Int(Double(matched.components(separatedBy: CharacterSet.letters).joined()) ?? 100)
            }

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
            
            let item = FoodItem(
                name: name,
                weightInGrams: servingAmount ?? 100,
                servings: 1,
                calories: Int(nutriments["energy-kcal_100g"] as? Double ?? 0),
                protein: nutriments["proteins_100g"] as? Double ?? 0,
                carbs: nutriments["carbohydrates_100g"] as? Double ?? 0,
                fats: nutriments["fat_100g"] as? Double ?? 0,
                servingUnit: unit
            )

            DispatchQueue.main.async {
                self.onScanned?(item)
                self.dismiss(animated: true)
            }
        }.resume()
    }
}
