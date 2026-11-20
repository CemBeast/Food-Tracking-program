//
//  KeyboardSwipeToDismiss.swift
//  FoodTrackingApp
//
//  Swipe down to dismiss the keyboard on any screen with text input.
//

import SwiftUI
import UIKit

private struct KeyboardSwipeToDismiss: ViewModifier {
    /// Screens without a ScrollView/List need an explicit drag gesture.
    /// Screens that scroll must NOT get one, since a DragGesture on scroll
    /// content can block scrolling on newer iOS versions.
    let usesDragGesture: Bool
    @State private var keyboardVisible = false

    func body(content: Content) -> some View {
        // usesDragGesture is fixed per screen, so this branch never flips at runtime.
        if usesDragGesture {
            base(content.contentShape(Rectangle()).simultaneousGesture(swipeDown))
        } else {
            base(content)
        }
    }

    private func base<V: View>(_ content: V) -> some View {
        content
            // Scroll views inside this screen dismiss the keyboard as you drag down.
            .scrollDismissesKeyboard(.interactively)
            // While the keyboard is up, a downward swipe should close the
            // keyboard, not the whole sheet. A second swipe closes the sheet.
            .interactiveDismissDisabled(keyboardVisible)
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
                keyboardVisible = true
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                keyboardVisible = false
            }
    }

    private var swipeDown: some Gesture {
        DragGesture(minimumDistance: 20)
            .onEnded { value in
                let dy = value.translation.height
                // Mostly-vertical downward swipe.
                if dy > 40 && abs(value.translation.width) < dy {
                    UIApplication.shared.endEditing()
                }
            }
    }
}

extension View {
    /// Swipe down anywhere on the screen to dismiss the keyboard.
    /// Pass `usesDragGesture: true` for screens that don't scroll.
    func keyboardSwipeToDismiss(usesDragGesture: Bool = false) -> some View {
        modifier(KeyboardSwipeToDismiss(usesDragGesture: usesDragGesture))
    }
}
