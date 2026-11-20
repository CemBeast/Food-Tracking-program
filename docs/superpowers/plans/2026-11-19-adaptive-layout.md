# Adaptive Layout Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Every iPhone renders the iPhone 13 Pro Max layout, scaled proportionally by width, with zero functional changes.

**Architecture:** A single global factor `Layout.scale = min(1, portraitScreenWidth / 428)`. A `.scaled` property on `Int`/`Double`/`CGFloat` multiplies a 13-Pro-Max-point literal by it. Every layout literal (font size, padding, spacing, frame, radius, offset, thick line width, shadow radius) is suffixed with `.scaled`. The factor is static because a phone's screen never changes. It uses the shorter screen side, so it's orientation-proof and works in sheets and UIKit without environment plumbing.

**Tech Stack:** SwiftUI, iOS 16+, Xcode 26 / iOS 26.5 simulators.

**Spec:** `docs/superpowers/specs/2026-11-19-adaptive-layout-design.md`

## Global Constraints

- Reference width 428pt (iPhone 13 Pro Max); scale capped at 1.0.
- No functional change and no rearranging; no horizontal ScrollView for chips.
- No commits (Cem's instruction).
- Don't touch `MachineLearning/` or `Meal Tracker/`.
- Hairline strokes (lineWidth ≤ 1.5), opacity, animation durations, `scaleEffect`, `minimumScaleFactor` are NOT scaled.
- System chrome (UINavigationBar/UITabBar appearance fonts) is NOT scaled.

## Review Focus

- Literals hidden in ternaries/defaults (`size: a ? 14 : 12`, `var padding: CGFloat = 16`): the second branch is missed by regex. Sweep grep after conversion.
- Non-layout `width:`/`height:` (CGSize for camera/images, UIKit rects) must not be scaled blindly. Review UIKit files by hand.
- SE vertical overflow on non-scrolling screens: report to Cem, don't add ScrollViews silently.
- 13 Pro Max must be pixel-identical (scale == 1). Verify by screenshot.
- Landscape is enabled for iPhone in the project settings. Scale uses the shorter side, so it's unaffected. Flag to Cem only.

---

### Task 1: Scale toolkit
**Files:** Create `FoodTrackingApp/FoodTrackingApp/AppAndTheme/AdaptiveLayout.swift`
**Produces:** `enum Layout { static let referenceWidth: CGFloat = 428; static let scale: CGFloat }`, `extension Int/Double/CGFloat { var scaled: CGFloat }`
- [ ] Implement; scale from `UIScreen.main.bounds` min(width, height) / 428, clamped to ≤ 1.
- [ ] Build passes.

### Task 2: Mechanical conversion of all view files
**Files:** every `.swift` under `FoodTrackingApp/FoodTrackingApp/` except `MachineLearning/`, the model/service files, and `AdaptiveLayout.swift`.
- [ ] Run the regex converter (scratchpad script) over the literal positions: `size:`, `spacing:`, `.padding(N)`, `.padding(.edge, N)`, `cornerRadius:`, `width:/height:/min*/max*:` in `.frame`, `minLength:`, `radius:`, `lineWidth:` > 1.5, `x:/y:` in `offset`/`shadow`, `.tracking(N)`, `.offset(N)`.
- [ ] Hand-review each file's diff; fix defaults/ternaries/UIKit.
- [ ] Sweep grep for remaining bare numeric literals in layout modifiers; convert or justify.
- [ ] Build passes.

### Task 3: Visual verification
- [ ] Install on Adapt 13PM / Adapt 14 / Adapt SE3; screenshot every screen (Track, Dictionary, Add/Edit Food, Meal Builder, LookUp, QuickTrack, History, Goals, Wizard, Tips, Settings).
- [ ] 13PM matches pre-change screenshots (take baseline before Task 2).
- [ ] 14/SE: no clipping or overflow; list anything questionable for Cem.
- [ ] Hand Cem the manual test steps and the flag list.
