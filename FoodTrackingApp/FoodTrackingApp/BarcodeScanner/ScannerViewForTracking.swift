//
//  ScannerViewForTracking.swift
//  FoodTrackingApp
//
//  Created by Cem Beyenal on 5/20/25.
//
import SwiftUI

struct ScannerViewForTracking: View {
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

