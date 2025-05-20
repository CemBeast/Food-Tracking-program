//
//  ScannerViewForTracking.swift
//  FoodTrackingApp
//
//  Created by Cem Beyenal on 5/20/25.
//
import SwiftUI

struct ScannerViewForTracking: UIViewControllerRepresentable {
    
    var onScanned: (FoodItem) -> Void

    func makeUIViewController(context: Context) -> ScannerTrackingViewController {
        let vc = ScannerTrackingViewController()
        vc.onScanned = onScanned
        return vc
    }

    func updateUIViewController(_ uiViewController: ScannerTrackingViewController, context: Context) {}
}
