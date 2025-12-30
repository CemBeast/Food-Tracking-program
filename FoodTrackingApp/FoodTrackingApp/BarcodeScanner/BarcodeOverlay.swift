//
//  BarcodeOverlay.swift
//  FoodTrackingApp
//
//  Created by Cem Beyenal on 5/11/25.
//
import SwiftUI

struct BarcodeOverlay: View {
    var body: some View {
        VStack(spacing: 16) {
            Rectangle()
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [10, 6]))
                .foregroundColor(.white)
                .background(Color.clear)
                .cornerRadius(12)
                .overlay(
                    // Corner accents
                    GeometryReader { geo in
                        ZStack {
                            // Top-left corner
                            CornerAccent()
                                .position(x: 16, y: 16)
                            
                            // Top-right corner
                            CornerAccent()
                                .rotationEffect(.degrees(90))
                                .position(x: geo.size.width - 16, y: 16)
                            
                            // Bottom-left corner
                            CornerAccent()
                                .rotationEffect(.degrees(-90))
                                .position(x: 16, y: geo.size.height - 16)
                            
                            // Bottom-right corner
                            CornerAccent()
                                .rotationEffect(.degrees(180))
                                .position(x: geo.size.width - 16, y: geo.size.height - 16)
                        }
                    }
                )
            
            // Label below the scanner area
            HStack(spacing: 8) {
                Image(systemName: "barcode.viewfinder")
                    .font(.system(size: 16, weight: .semibold))
                Text("Align Barcode")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.6))
            )
        }
    }
}

struct CornerAccent: View {
    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 20))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 20, y: 0))
        }
        .stroke(Color.white, style: StrokeStyle(lineWidth: 3, lineCap: .round))
    }
}
