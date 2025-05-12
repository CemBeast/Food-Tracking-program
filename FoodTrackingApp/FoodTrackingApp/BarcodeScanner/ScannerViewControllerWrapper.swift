//
//  ScannerViewControllerWrapper.swift
//  FoodTrackingApp
//
//  Created by Cem Beyenal on 5/11/25.
//
import SwiftUI

struct ScannerViewControllerWrapper: UIViewControllerRepresentable {
    let foodModel: FoodModel

    func makeUIViewController(context: Context) -> ScannerViewController {
        return ScannerViewController(foodModel: foodModel)
    }

    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}
}
