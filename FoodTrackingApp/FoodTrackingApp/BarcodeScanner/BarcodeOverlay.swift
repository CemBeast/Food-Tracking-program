//
//  BarcodeOverlay.swift
//  FoodTrackingApp
//
//  Created by Cem Beyenal on 5/11/25.
//
import SwiftUI

struct BarcodeOverlay: View {
    var body: some View {
        Rectangle()
            .strokeBorder(style: StrokeStyle(lineWidth: 3, dash: [8]))
            .foregroundColor(.white)
            .background(Color.clear)
            .cornerRadius(12)
            .overlay(
                Text("Align Barcode")
                    .foregroundColor(.white)
                    .font(.headline)
                    .padding(.top, 160)
            )
    }
}
