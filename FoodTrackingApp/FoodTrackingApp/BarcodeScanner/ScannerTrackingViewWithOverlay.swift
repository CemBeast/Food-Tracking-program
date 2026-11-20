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
    var onError: (BarcodeLookupError) -> Void
    @State private var isLooking = false

    var body: some View {
        ZStack {
            // Camera view
            ScannerTrackingViewWrapper(
                onScanned: { food in
                    isLooking = false
                    onScanned(food)
                },
                onError: { err in
                    isLooking = false
                    onError(err)
                },
                onLookupStarted: {
                    isLooking = true
                }
            )
            .edgesIgnoringSafeArea(.all)

            // Overlay UI
            VStack {
                // Top bar
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16.scaled, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(12.scaled)
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(0.5))
                            )
                    }

                    Spacer()

                    Text("Add by Barcode")
                        .font(.system(size: 17.scaled, weight: .semibold))
                        .foregroundColor(.white)

                    Spacer()

                    Color.clear
                        .frame(width: 40.scaled, height: 40.scaled)
                }
                .padding(.horizontal, 20.scaled)
                .padding(.top, 60.scaled)

                Spacer()

                // Barcode overlay
                BarcodeOverlay()
                    .frame(width: 280.scaled, height: 180.scaled)

                Spacer()

                // Bottom hint
                Text("Position barcode within the frame")
                    .font(.system(size: 14.scaled))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.bottom, 40.scaled)
            }

            if isLooking {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                VStack(spacing: 12.scaled) {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                        .scaleEffect(1.4)
                    Text("Looking up…")
                        .font(.system(size: 14.scaled, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(20.scaled)
                .background(
                    RoundedRectangle(cornerRadius: 12.scaled)
                        .fill(Color.black.opacity(0.7))
                )
                .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.15), value: isLooking)
    }
}
