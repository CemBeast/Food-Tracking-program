//
//  BarcodeDelegate.swift
//  FoodTrackingApp
//
//  Created by Cem Beyenal on 5/11/25.
//
import AVFoundation

class BarcodeDelegate: NSObject, AVCaptureMetadataOutputObjectsDelegate {
    var onScan: (String) -> Void

    init(onScan: @escaping (String) -> Void) {
        self.onScan = onScan
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        guard let metadata = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let code = metadata.stringValue else {
            return
        }
        onScan(code)
    }
}
