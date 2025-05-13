//
//  BarcodeScannerView.swift
//  FoodTrackingApp
//
//  Created by Cem Beyenal on 5/11/25.
//
import SwiftUI

struct BarcodeScannerView: View {
    let foodModel: FoodModel

    var body: some View {
        ZStack {
            // UIKit camera controller (wrapped)
            ScannerViewControllerWrapper(foodModel: foodModel)
                .edgesIgnoringSafeArea(.all)
            BarcodeOverlay()
                    .frame(width: 300, height: 200)
                    .padding(.bottom, 100)
        }
    }
}
