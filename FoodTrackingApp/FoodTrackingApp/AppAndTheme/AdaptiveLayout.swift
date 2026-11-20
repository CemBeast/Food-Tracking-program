//
//  AdaptiveLayout.swift
//  FoodTrackingApp
//
//  Every layout number in the app is written in "iPhone 13 Pro Max points"
//  (the reference device, 428pt wide). Append `.scaled` to a literal and it
//  is shrunk proportionally on narrower iPhones, so every phone shows the
//  same layout as the 13 Pro Max, just smaller. Wider phones are capped at
//  1.0 so they look identical to the reference.
//
//      .font(.system(size: 14.scaled))
//      .padding(.horizontal, 20.scaled)
//
//  Do NOT scale hairline strokes, opacity, durations, scaleEffect or
//  minimumScaleFactor.
//

import SwiftUI
import UIKit

enum Layout {
    /// Portrait width of the iPhone 13 Pro Max, the design reference.
    static let referenceWidth: CGFloat = 428

    /// Multiplier applied to every layout literal. Computed once: a phone's
    /// screen never changes, and using the shorter side keeps it stable in
    /// landscape too.
    static let scale: CGFloat = {
        let bounds = UIScreen.main.bounds
        let portraitWidth = min(bounds.width, bounds.height)
        guard portraitWidth > 0 else { return 1 }
        return min(1, portraitWidth / referenceWidth)
    }()

    /// Portrait height of the iPhone 13 Pro Max.
    static let referenceHeight: CGFloat = 926

    /// How much taller a half-height sheet must be on this phone to hold the
    /// same (scaled) content as on the 13 Pro Max. 1.0 on phones whose height
    /// shrinks at least as much as their width; > 1 only on proportionally
    /// short screens like the iPhone SE.
    static let mediumSheetBoost: CGFloat = {
        let bounds = UIScreen.main.bounds
        let portraitHeight = max(bounds.width, bounds.height)
        guard portraitHeight > 0 else { return 1 }
        return max(1, scale * referenceHeight / portraitHeight)
    }()
}

/// Half-height sheet that holds the same content on every phone: exactly the
/// system `.medium` wherever that already fits, slightly taller on
/// proportionally short screens (iPhone SE).
private struct ScaledMediumDetent: CustomPresentationDetent {
    static func height(in context: Context) -> CGFloat? {
        context.maxDetentValue * 0.5 * Layout.mediumSheetBoost
    }
}

extension PresentationDetent {
    static var scaledMedium: PresentationDetent {
        Layout.mediumSheetBoost > 1.001 ? .custom(ScaledMediumDetent.self) : .medium
    }
}

extension View {
    /// Keeps the content laid out exactly as-is (pinned to the top) when it
    /// fits. Content may run up to `tolerance` points past the bottom, which
    /// is how the tabs already behave on the 13 Pro Max (they slightly overlap
    /// their own bottom margin). Only when it overflows by more than that
    /// (e.g. iPhone SE, whose screen is proportionally much shorter) does it
    /// switch to a vertical scroll view, so phones where it fits never scroll.
    func scrollsIfNeeded(tolerance: CGFloat = 0) -> some View {
        ScrollIfNeeded(tolerance: tolerance, content: self)
    }
}

private struct NaturalHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

private struct ScrollIfNeeded<Content: View>: View {
    let tolerance: CGFloat
    let content: Content
    @State private var naturalHeight: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            Group {
                if naturalHeight <= geo.size.height + tolerance {
                    // Same as the original `.frame(maxHeight: .infinity, alignment: .top)`:
                    // if the content is a little taller than the space, the
                    // overflow is split evenly above and below (centered).
                    content
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .frame(width: geo.size.width, height: geo.size.height)
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        content.frame(width: geo.size.width, alignment: .top)
                    }
                }
            }
            .background(
                // Invisible copy at its natural height, used only to measure.
                content
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(width: geo.size.width)
                    .hidden()
                    .background(GeometryReader { Color.clear.preference(key: NaturalHeightKey.self, value: $0.size.height) }),
                alignment: .top
            )
        }
        .onPreferenceChange(NaturalHeightKey.self) { naturalHeight = $0 }
    }
}

extension Int {
    /// This value in 13 Pro Max points, scaled for the current phone.
    var scaled: CGFloat { CGFloat(self) * Layout.scale }
}

extension Double {
    /// This value in 13 Pro Max points, scaled for the current phone.
    var scaled: CGFloat { CGFloat(self) * Layout.scale }
}

extension CGFloat {
    /// This value in 13 Pro Max points, scaled for the current phone.
    var scaled: CGFloat { self * Layout.scale }
}
