//
//  ScannerTrackingViewWrapper.swift
//  FoodTrackingApp
//
//  Created by Cem Beyenal on 5/27/25.
//


import SwiftUI

struct ScannerTrackingViewWrapper: UIViewControllerRepresentable {
    var onScanned: (FoodItem) -> Void
    var onError: (BarcodeLookupError) -> Void
    var onLookupStarted: () -> Void

    func makeUIViewController(context: Context) -> ScannerTrackingViewController {
        let vc = ScannerTrackingViewController()
        vc.onScanned = onScanned
        vc.onError = onError
        vc.onLookupStarted = onLookupStarted
        return vc
    }

    func updateUIViewController(_ uiViewController: ScannerTrackingViewController, context: Context) {}
}
