//
//  KeyboardSwipeToDismiss.swift
//  FoodTrackingApp
//
//  App-wide "swipe down to dismiss the keyboard".
//
//  One pan recognizer on the app window covers every screen and sheet, so
//  individual views don't opt in. While the keyboard is up:
//   - a downward swipe anywhere (search bars, headers, scroll views,
//     number-pad screens) closes the keyboard;
//   - the top sheet is locked so that same swipe can't also close it.
//  Once the keyboard is gone, a normal swipe closes the sheet as usual.
//

import UIKit

final class KeyboardSwipeDismiss: NSObject, UIGestureRecognizerDelegate {
    static let shared = KeyboardSwipeDismiss()

    private var keyboardVisible = false
    private var panActive = false
    private var dismissedThisGesture = false
    private weak var lockedSheet: UIViewController?
    private var lockedSheetWasModal = false

    /// Call once at launch.
    func start() {
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(keyboardWillShow),
                       name: UIResponder.keyboardWillShowNotification, object: nil)
        nc.addObserver(self, selector: #selector(keyboardWillHide),
                       name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    // MARK: Keyboard

    @objc private func keyboardWillShow() {
        keyboardVisible = true
        guard let window = appWindow else { return }
        installIfNeeded(on: window)
        lockTopSheet(in: window)
    }

    @objc private func keyboardWillHide() {
        keyboardVisible = false
        // If the hide came from our swipe, wait for the finger to lift before
        // unlocking, or the same swipe would go on to close the sheet.
        if !panActive { unlockSheet() }
    }

    private var appWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
    }

    // MARK: Sheet lock

    private func lockTopSheet(in window: UIWindow) {
        var top = window.rootViewController
        while let next = top?.presentedViewController { top = next }
        guard let sheet = top, sheet !== window.rootViewController else {
            unlockSheet()
            return
        }
        // keyboardWillShow fires again on every field change; only act on a new sheet.
        if sheet === lockedSheet { return }
        unlockSheet()
        lockedSheetWasModal = sheet.isModalInPresentation
        sheet.isModalInPresentation = true
        lockedSheet = sheet
    }

    private func unlockSheet() {
        lockedSheet?.isModalInPresentation = lockedSheetWasModal
        lockedSheet = nil
    }

    // MARK: Gesture

    private func installIfNeeded(on window: UIWindow) {
        let installed = window.gestureRecognizers?.contains { $0.delegate === self } ?? false
        guard !installed else { return }
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.cancelsTouchesInView = false   // never steal taps/drags from the UI
        pan.delaysTouchesBegan = false
        pan.delaysTouchesEnded = false
        pan.delegate = self
        window.addGestureRecognizer(pan)
    }

    @objc private func handlePan(_ pan: UIPanGestureRecognizer) {
        switch pan.state {
        case .began:
            panActive = true
            dismissedThisGesture = false
        case .changed, .ended:
            if !dismissedThisGesture {
                let t = pan.translation(in: pan.view)
                let v = pan.velocity(in: pan.view)
                let mostlyDown = t.y > abs(t.x)
                let farEnough = t.y > 40
                let flick = pan.state == .ended && t.y > 10 && v.y > 500
                if mostlyDown && (farEnough || flick) {
                    dismissedThisGesture = true
                    pan.view?.endEditing(true)
                }
            }
            if pan.state == .ended { panFinished() }
        case .cancelled, .failed:
            panFinished()
        default:
            break
        }
    }

    private func panFinished() {
        panActive = false
        if !keyboardVisible { unlockSheet() }
    }

    // Only run while the keyboard is up, so it never interferes otherwise.
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        keyboardVisible
    }

    // Run alongside scroll views, sheet drags and SwiftUI gestures.
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
        true
    }

    // Ignore drags that start on a text field, so moving the cursor or
    // selecting text doesn't close the keyboard mid-edit.
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldReceive touch: UITouch) -> Bool {
        var view = touch.view
        while let v = view {
            if v is UITextField || v is UITextView { return false }
            view = v.superview
        }
        return true
    }
}
