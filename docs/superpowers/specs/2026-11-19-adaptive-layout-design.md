# Adaptive Layout Pass — Design

Date: 2026-11-19

## Intent

Cem builds and uses the app on an iPhone 13 Pro Max (428×926pt), where it looks and works exactly as intended. On smaller phones the layout breaks. The first known case: the Dictionary sort chips overflow on iPhone 14 (390pt). Goal: every other iPhone shows the same screen as the 13 Pro Max, proportionally scaled to fit. Nothing is added, removed, rearranged or changed in behavior.

## Goals

- On every iPhone supported by iOS 16 (smallest: 375×667pt, i.e. SE 2/3, 8, 12/13 mini), every screen looks like the 13 Pro Max version, scaled down to fit.
- No layout number tied to one phone. All sizes are expressed relative to the reference phone and scaled at runtime.
- Zero functional changes.

## Non-goals

- Dynamic Type / Larger Text (Cem's call, for now).
- iPad, landscape.
- Any redesign, new UI patterns, or behavior change.
- `MachineLearning/` (dormant) and `Meal Tracker/` (frozen).

## Anti-goals

- Horizontal scroll views for chip rows. Cem explicitly doesn't want them. Chips shrink instead.
- Rearranging, wrapping, or hiding anything so it fits differently than on the 13 Pro Max.
- Any change to how the app behaves.

## Approaches considered (execution)

- **A. One agent, one screen at a time (chosen).**
- B. Parallel subagents with a shared rulebook. Not chosen.
- C. Subagents consulting a coordinator live. Rejected because decisions drift.

## Approaches considered (technique)

- **Proportional scaling from a reference width (chosen).** Every literal in the code is treated as a "13 Pro Max point" and multiplied by `scale = screenWidth / 428` at runtime. Small phones become a faithful scaled-down copy. This matches "look the same" directly.
- Targeted fixes only where something overflows (shrink-to-fit text, flexible widths). Not chosen: screens would end up looking different from the 13 Pro Max in inconsistent ways.

## How it works

1. **One scale factor.** `scale = min(1.0, screenWidth / 428)`. It is computed once from the window width at the app root and provided via the SwiftUI environment. It is capped at 1.0, so the 14/15/16 Pro Max and 16/17 Pro Max (430–440pt) look identical to the 13 Pro Max rather than slightly enlarged. The builder must verify the value reaches sheets and full-screen covers; if it doesn't, the root re-injects it there.
2. **Scaled helpers** in a new `AppAndTheme/AdaptiveLayout.swift`:
   - fonts: `.font(.system(size: 12, weight: .medium))` becomes a scaled equivalent such as `.scaledFont(size: 12, weight: .medium)`
   - padding, spacing, frames, corner radii, offsets, line widths: wrapped in the scale (`s(14)` or similar)
   - The original 13 Pro Max numbers stay visible in the code, so they're easy to read and tweak.
3. **Every view file** is converted: all layout literals (fonts, padding, spacing, frames, radii) go through the scale. That includes `AppTheme.swift` button styles, cards, and text fields. System chrome (nav bar, tab bar, `List` row insets, sheets) is left alone.
4. **Vertical exception.** The SE is proportionally shorter (667 vs 926, a 0.72 ratio vs 0.876 for width). Screens that already scroll are fine. If a non-scrolling screen still doesn't fit vertically on the SE after scaling, the builder reports it to Cem with a screenshot before changing anything. No silent ScrollView additions.

## Process

1. Audit every view file: what's a fixed screen vs. what already scrolls, and where the literals are.
2. Add `AdaptiveLayout.swift` and convert `AppTheme.swift`. Build.
3. Screen by screen, in this order: Dictionary, then MainMenu tabs, QuickTrack, Add/Edit Food, Meal Builder/Ingredients, LookUp, History/Rings, Goals/Wizard, Scanner, Tips. For each: convert, build, screenshot on iPhone SE 3, iPhone 14, and 13 Pro Max (reference: it must look unchanged), give Cem manual test steps.
4. Final sweep: grep for any remaining unscaled numeric literal in layout modifiers and justify or convert each one.

## Left to the builder

- Exact helper names and API shape.
- How the root measures width (e.g. `GeometryReader` at the root, or window scene bounds).
- Whether hairline values (1pt strokes) scale. Default: no.
- Scanner overlay can't be checked in the simulator. Give manual steps.
