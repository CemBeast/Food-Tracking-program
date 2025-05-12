//
//  VideoCaptureView.swift
//  FoodTrackingApp
//
//  Created by Cem Beyenal on 5/11/25.
//
import SwiftUI
import AVFoundation

struct VideoCaptureView: UIViewRepresentable {
    @Binding var captureSession: AVCaptureSession?
    @Binding var videoPreviewLayer: AVCaptureVideoPreviewLayer?

    func makeUIView(context: Context) -> UIView {
        print("🎥 makeUIView() called")
        let view = UIView()
        view.backgroundColor = .black
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let previewLayer = videoPreviewLayer else {
            print("⚠️ No preview layer to show")
            return
        }

        previewLayer.frame = uiView.bounds

        // Remove any existing preview layers first
        if previewLayer.superlayer == nil {
            print("📐 Adding preview layer to view")
            uiView.layer.insertSublayer(previewLayer, at: 0)
        }
    }
}
