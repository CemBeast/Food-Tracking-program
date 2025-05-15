//
//  ScannerViewController.swift
//  FoodTrackingApp
//
//  Created by Cem Beyenal on 5/11/25.
//


import UIKit
import AVFoundation

class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    let foodModel: FoodModel
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!

    init(foodModel: FoodModel) {
        self.foodModel = foodModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black
        captureSession = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            print("❌ No camera found")
            return
        }

        do {
            let videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            } else {
                print("❌ Could not add camera input")
                return
            }
        } catch {
            print("❌ Camera input error: \(error)")
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.ean8, .ean13, .code128]
        } else {
            print("❌ Could not add metadata output")
            return
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
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
           let code = metadataObject.stringValue {
            print("Scanned: \(code)")
            
            lookupFood(barcode: code)

            captureSession.stopRunning()
            dismiss(animated: true)
        }
    }
    
    func lookupFood(barcode: String) {
        let urlString = "https://world.openfoodfacts.org/api/v0/product/\(barcode).json"
        guard let url = URL(string: urlString) else { return }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Network error: \(error?.localizedDescription ?? "unknown")")
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data)  as? [String: Any]
                guard let product = json?["product"] as? [String: Any],
                      let name = product["product_name"] as? String,
                      let nutriments = product["nutriments"] as? [String: Any] else {
                    print("Invalid JSON structure")
                    return
                }
                let servingString = product["serving_size"] as? String ?? ""
                let servingsGram: Int? = {
                    let pattern = #"(\d+(?:\.\d+)?)\s*g"#
                    if let match = servingString.range(of: pattern, options: .regularExpression) {
                        let numberString = servingString[match]
                            .replacingOccurrences(of: "g", with: "")
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                        return Int(Double(numberString) ?? 100)
                    }
                    return nil
                }()
                
                let calories = nutriments["energy-kcal_serving"] as? Int ??
                               nutriments["energy-kcal_100g"] as? Int ?? 0

                let protein = nutriments["proteins_serving"] as? Double ??
                              nutriments["proteins_100g"] as? Double ?? 0

                let carbs = nutriments["carbohydrates_serving"] as? Double ??
                            nutriments["carbohydrates_100g"] as? Double ?? 0

                let fats = nutriments["fat_serving"] as? Double ??
                           nutriments["fat_100g"] as? Double ?? 0
                
                let item = FoodItem(
                    name:name,
                    weightInGrams: servingsGram ?? 100,
                    servings: 1,
                    calories: calories,
                    protein: protein,
                    carbs: carbs,
                    fats: fats
                )
                
                DispatchQueue.main.async {
                    self.foodModel.add(item)
                    self.captureSession.stopRunning()
                    self.dismiss(animated: true)
                }
            } catch {
                print("JSON parse error: \(error.localizedDescription)")
            }
        }
        task.resume()
    }
    
}
