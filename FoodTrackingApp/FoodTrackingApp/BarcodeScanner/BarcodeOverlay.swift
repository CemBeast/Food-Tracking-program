//
//  BarcodeOverlay.swift
//  FoodTrackingApp
//
//  Created by Cem Beyenal on 5/11/25.
//
import SwiftUI

struct BarcodeOverlay: View {
    var body: some View {
        VStack(spacing: 16.scaled) {
            Rectangle()
                .strokeBorder(style: StrokeStyle(lineWidth: 2.scaled, dash: [10.scaled, 6.scaled]))
                .foregroundColor(.white)
                .background(Color.clear)
                .cornerRadius(12.scaled)
                .overlay(
                    // Corner accents
                    GeometryReader { geo in
                        ZStack {
                            // Top-left corner
                            CornerAccent()
                                .position(x: 16.scaled, y: 16.scaled)
                            
                            // Top-right corner
                            CornerAccent()
                                .rotationEffect(.degrees(90))
                                .position(x: geo.size.width - 16.scaled, y: 16.scaled)
                            
                            // Bottom-left corner
                            CornerAccent()
                                .rotationEffect(.degrees(-90))
                                .position(x: 16.scaled, y: geo.size.height - 16.scaled)
                            
                            // Bottom-right corner
                            CornerAccent()
                                .rotationEffect(.degrees(180))
                                .position(x: geo.size.width - 16.scaled, y: geo.size.height - 16.scaled)
                        }
                    }
                )
            
            // Label below the scanner area
            HStack(spacing: 8.scaled) {
                Image(systemName: "barcode.viewfinder")
                    .font(.system(size: 16.scaled, weight: .semibold))
                Text("Align Barcode")
                    .font(.system(size: 15.scaled, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16.scaled)
            .padding(.vertical, 10.scaled)
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
            path.move(to: CGPoint(x: 0, y: 20.scaled))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 20.scaled, y: 0))
        }
        .stroke(Color.white, style: StrokeStyle(lineWidth: 3.scaled, lineCap: .round))
    }
}
