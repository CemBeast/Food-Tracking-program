//
//  ScannerTrackingViewWithOverlay.swift
//  FoodTrackingApp
//
//  Created by Cem Beyenal on 5/27/25.
//

import SwiftUI

struct ScannerTrackingViewWithOverlay: View {
    @Environment(\.dismiss) private var dismiss
    var onScanned: (FoodItem) -> Void

    var body: some View {
        ZStack {
            // Camera view
            ScannerTrackingViewWrapper(onScanned: onScanned)
                .edgesIgnoringSafeArea(.all)
            
            // Overlay UI
            VStack {
                // Top bar
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(0.5))
                            )
                    }
                    
                    Spacer()
                    
                    Text("Add by Barcode")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Color.clear
                        .frame(width: 40, height: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                
                Spacer()
                
                // Barcode overlay
                BarcodeOverlay()
                    .frame(width: 280, height: 180)
                
                Spacer()
                
                // Bottom hint
                Text("Position barcode within the frame")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.bottom, 40)
            }
        }
    }
}
