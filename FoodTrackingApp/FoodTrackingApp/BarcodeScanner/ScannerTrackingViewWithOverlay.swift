//
//  ScannerTrackingViewWithOverlay.swift
//  FoodTrackingApp
//
//  Created by Cem Beyenal on 5/27/25.
//


import SwiftUI

struct ScannerTrackingViewWithOverlay: View {
    var onScanned: (FoodItem) -> Void

    var body: some View {
        ZStack {
            ScannerTrackingViewWrapper(onScanned: onScanned)
                .edgesIgnoringSafeArea(.all)

            BarcodeOverlay()
                .frame(width: 300, height: 200)
                .padding(.bottom, 100)
        }
    }
}