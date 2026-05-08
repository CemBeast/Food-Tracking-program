# Meal Tracker

A macro-tracking application maintained in two implementations:

- **`FoodTrackingApp/`** — SwiftUI iOS app (active, shipping on TestFlight).
- **`Meal Tracker/`** — Original C++ terminal prototype (frozen, kept for reference).

The iOS app is the supported product. Everything below describes it unless otherwise noted.

---

## FoodTrackingApp (iOS)

A SwiftUI app for tracking daily calories, protein, carbs, and fats. Foods come from a bundled USDA-derived seed, the live USDA FoodData Central API, manual entry, or barcode scanning. Meals can be composed from multiple foods and logged as a single unit.

### Requirements

- iOS 16.0+
- Xcode 15.0+ / macOS Monterey+
- A USDA FoodData Central API key (only needed at build time to regenerate bundled defaults, and at runtime for live lookup — see [Configuration](#configuration))

### TestFlight

https://testflight.apple.com/join/1gzU61Ck

---

### Features

#### Daily tracking
- Daily totals for calories, protein, carbs, and fats with ringed visual display.
- Goal overflow renders a distinct outer ring once a target is exceeded.
- Tap the display to toggle between **consumed** and **remaining** views.
- Per-food log for the current day, with edit and delete.
- Automatic midnight rollover. The app re-checks on `UIApplication.didBecomeActiveNotification`, so leaving the app open across days still rolls correctly.

#### Goals
- Manual goal editor for calories/P/C/F.
- Macro Goal Wizard: estimates targets from sex, age, height, weight, activity level, and weight-change goal (sedentary → very active; ±2 lb/week range).
- Initial-goal prompt on first launch with three paths: edit manually, run the wizard, or accept defaults (2000/150/250/70).

#### Food dictionary
- Bundled USDA-derived seed (`default_all.json`) installed on first launch.
- Versioned wipe-and-reseed migration controlled by `bundledDefaultsVersion` in `FoodStorage.swift`. Bumping the version replaces the user's dictionary on next launch (FoodTrackingApp is single-user; preserving local edits across reseeds is intentionally not supported).
- Manual add/edit/delete for individual foods.
- Favorites and search filters (name / calories / favorites / meals).
- Per-food serving unit (grams or milliliters) and per-food serving size.

#### USDA live lookup
- Three search scopes exposed as **Basic** (SR Legacy → Foundation fallback), **Everyday** (Survey/FNDDS), and **Brands** (Branded). Implemented in `USDANutritionService.swift`.
- Top-N results fetched up front; per-result macro previews stream in concurrently via a `TaskGroup` and cache by `fdcId` for the session.
- Handles the Foundation "kcal=0 with nonzero macros" case (the lettuce bug) by walking the fallback chain when the primary hit looks unusable.

#### Barcode scanning
- AVFoundation-based scanner used in two places:
  - **Dictionary**: scan to add a product to your library.
  - **Track**: scan to log a product directly to today's totals; a confirmation dialog asks whether to track by weight/volume or by serving.

#### Meal builder
- Compose a meal from multiple dictionary foods. Macros are summed automatically as ingredients and quantities change.
- Saved meals are first-class dictionary entries: log them like any other food.
- Ingredients are individually editable after save (quantity changes propagate to the meal totals).
- Cooked-weight adjustment: override the parent meal's total weight without touching ingredients (e.g., when liquid loss changes the per-gram density of the finished dish).

#### Quick Track
- One-shot logging of a calorie/macro entry without committing it to the dictionary. Useful for one-off meals you don't want polluting your library.

#### History
- Per-day history list with daily averages computed across all stored entries.
- Tap a day to see the foods eaten on that date.
- Swipe-to-delete on individual history entries; "Clear History" wipes the whole archive.

#### Onboarding
- Tips & Tricks sheet auto-presented on first launch and reachable any time from Settings. First-launch flow chains into the goal prompt once dismissed.

---

### Architecture

```
FoodTrackingApp/
├── FoodTrackingApp/
│   ├── AppAndTheme/                  # App entry, theme, onboarding
│   │   ├── FoodTrackingAppApp.swift  # @main
│   │   ├── AppTheme.swift            # Colors, typography, button styles
│   │   ├── TipsAndTricksView.swift   # First-launch / settings tour
│   │   └── Utils/                    # Shared view helpers
│   ├── MainMenu.swift                # Root NavigationView + 4-tab TabView
│   ├── Dictionary Info/              # Food dictionary + USDA UI
│   │   ├── DictionaryView.swift      # Browsing / search / filters
│   │   ├── FoodModel.swift           # ObservableObject; in-memory dictionary
│   │   ├── FoodStorage.swift         # JSON persistence + seed/migration
│   │   ├── AddFoodView.swift         # Manual entry
│   │   ├── EditFoodItemView.swift    # Field-level editor (also used for USDA confirm)
│   │   ├── EditQuantityView.swift    # Quantity tweak surface
│   │   ├── IngredientsView.swift     # Inspect/edit a saved meal's ingredients
│   │   ├── MealBuilderView.swift     # Compose new meals
│   │   ├── LookUpFoodView.swift      # USDA search UI (3 scopes)
│   │   └── default_all.json          # Bundled seed (per 100g, deterministic UUIDs)
│   ├── USDALookUp/
│   │   ├── USDANutritionService.swift # FoodData Central client
│   │   └── FoodQueryType.swift
│   ├── BarcodeScanner/               # AVFoundation barcode pipeline
│   │   ├── ScannerViewController.swift          # Dictionary-add path
│   │   ├── ScannerTrackingViewController.swift  # Tracking path
│   │   ├── BarcodeOverlay.swift                 # Reticle / hit feedback
│   │   └── Wrapper / SwiftUI bridges
│   ├── Tracking/
│   │   ├── MacroTrackerViewModel.swift # Daily totals, food log, goal state
│   │   ├── GramsOrServingsInput.swift  # Quantity input with live preview
│   │   └── QuickTrackView.swift        # One-shot calorie/macro entry
│   ├── MacroHistoryAndLogs/
│   │   ├── DailyMacrosDisplay.swift    # Header rings (consumed vs remaining)
│   │   ├── FoodLogView.swift           # Today's log
│   │   ├── FoodLogViewForDate.swift    # Historical day view
│   │   └── MacroHistoryView.swift      # Daily averages + history list
│   ├── MacroGoals/
│   │   ├── EditGoalsView.swift         # Manual goal edit
│   │   └── MacroGoalWizardView.swift   # Sex/age/activity → kcal + macro split
│   └── Info.plist / *.entitlements
└── tools/
    ├── seed_usda_defaults.py         # Curated-list builder against USDA FDC
    ├── build_log.csv                 # Per-food source/fdcId/macros audit log
    └── README.md
```

The four tabs (`Dictionary`, `Track`, `History`, `Settings`) all share a fixed minimum content height (`tabContentMinHeight` in `MainMenu.swift`) so SwiftUI doesn't stretch shorter tabs to fill the available vertical space.

### State and persistence

| State | Mechanism |
|---|---|
| Food dictionary (foods + meals) | `user_foods.json` in the app's Documents directory, written via `FoodStorage.swift` |
| Bundled seed | `default_all.json` in the app bundle, gated by `bundledDefaultsVersion` |
| Daily totals (cal/P/C/F) | `UserDefaults` keys, persisted reactively via Combine `sink` on each `@Published` |
| Today's food log | `UserDefaults` (JSON-encoded `[LoggedFoodEntry]`) |
| Macro history | `UserDefaults` (JSON-encoded `[MacroHistoryEntry]`) |
| Goals | `UserDefaults` |
| Last-updated date (rollover) | `UserDefaults`, normalized to `startOfDay` |
| First-launch tips flag | `@AppStorage("hasSeenTipsAndTricks")` |

`MacroTrackerViewModel` initializes by hydrating all of the above, then wires Combine `sink`s so any `@Published` mutation is mirrored to `UserDefaults` without explicit save calls. Day-rollover is checked once at init and again on every foreground transition.

### Configuration

The USDA API key is read from the `FDC_API_KEY` Info.plist value (sourced from `Secrets.xcconfig`). Without it, live USDA lookup throws a 900 error; the rest of the app continues to work against the bundled seed and manually-added foods.

To set up the key locally, create `Secrets.xcconfig` (gitignored) at the project root with:

```
FDC_API_KEY = your_key_here
```

Get a key at https://fdc.nal.usda.gov/api-key-signup.html.

### Regenerating the bundled food seed

The seed lives in `FoodTrackingApp/FoodTrackingApp/Dictionary Info/default_all.json` and is generated from `tools/seed_usda_defaults.py`. The curated list (`CURATED_FOODS`) and the per-food preferred source (`sr_legacy` vs `survey`) live inline in that script.

```bash
export FDC_API_KEY="YOUR_KEY_HERE"
python3 tools/seed_usda_defaults.py \
  --out "FoodTrackingApp/FoodTrackingApp/Dictionary Info/default_all.json" \
  --log tools/build_log.csv
```

Each run:
- Walks the source-specific fallback chain (`SR Legacy → Foundation → Survey` for `sr_legacy`; `Survey → SR Legacy → Foundation` for `survey`), with the lettuce-bug guard.
- Writes deterministic UUIDs derived from the friendly name (re-runs produce stable IDs).
- Normalizes everything to per-100g (`weightInGrams=100`, `servings=1`, `servingUnit="g"`).
- Appends an audit row per food to `build_log.csv` so you can spot non-preferred-source fallbacks before shipping.

After regenerating, **bump `bundledDefaultsVersion` in `FoodStorage.swift`** and rebuild. On next launch, the app will wipe `user_foods.json` and reseed from the new bundle.

See [`tools/README.md`](tools/README.md) for the full flag set.

### Tech stack

- **SwiftUI** + **Combine** for UI and reactive state.
- **AVFoundation** (`AVCaptureSession`, `AVCaptureMetadataOutput`) for barcode scanning.
- **URLSession** + structured concurrency (`async`/`await`, `TaskGroup`) for USDA calls.
- **UserDefaults** + `FileManager`-backed JSON for persistence (no Core Data, no CloudKit).
- **USDA FoodData Central API** at build time (seed generation) and runtime (live lookup).

### Build

```bash
open FoodTrackingApp/FoodTrackingApp.xcodeproj
# select a simulator or device, then ⌘R
```

---

### Roadmap

- Home Screen widget (group container `group.com.yourname.FoodTrackingApp` is already wired in `MacroTrackerViewModel.saveDailyMacrosToDefaults`).
- iCloud sync for multi-device.
- Data export / import.
- Recipe scaling by serving count.
- Fast-food category in USDA lookup (mode placeholder is present; disabled).

### Known caveats

- USDA Foundation entries occasionally report `kcal=0` with non-zero P/C/F. Both the iOS service and the seed generator detect this and fall back to the next data source.
- The reseed migration is intentionally destructive — it replaces the user's dictionary, including saved meals, when `bundledDefaultsVersion` advances. Acceptable for a single-user app; revisit if multi-user state ever lands.
- An on-device CoreML food classifier was prototyped (`FoodClassifier.mlpackage`, 100+ classes). Accuracy wasn't shippable, so the entry point in `MainMenu.swift` is commented out and the model is not bundled into the active build. The supporting Swift files (`FoodMLPredictor`, `ConfirmFoodNameAndGramsView`, `ImagePicker`) remain in the tree pending a future replacement.

---

## C++ version (legacy)

Original terminal-based meal tracker in `Meal Tracker/`. Functional but no longer maintained — kept for reference. Use the iOS app for everything new.

---

## Support

Bug reports and feature requests via TestFlight feedback or by opening an issue.
