# Meal Tracker

A comprehensive macro tracking application available in two versions: a legacy C++ implementation and a modern SwiftUI iOS app.

## Overview

This repository contains two implementations of the Meal Tracker application:

- **`Meal Tracker/`** - Original C++ version (legacy, fully functional terminal-based tracker)
- **`FoodTrackingApp/`** - Modern SwiftUI iOS application (active development)

---

## C++ Version (Legacy)

The original terminal-based meal tracker implemented in C++. This version is fully functional and was used as the foundation for feature development before transitioning to iOS.

**Status**: Functional but no longer actively maintained. Kept for reference.

---

## SwiftUI Version (iOS)

A feature-rich iOS application for tracking daily macronutrients (calories, protein, carbs, and fats) with a beautiful, modern interface.

### Features

#### Core Tracking
- **Daily Macro Tracking**: Track calories, protein, carbs, and fats with visual ring indicators
- **Goal Management**: Set custom macro goals manually or use the built-in macro calculator wizard
- **Overflow Visualization**: See when you exceed your goals with a distinct outer ring indicator
- **Consumed vs Remaining Toggle**: Tap the display to switch between consumed and remaining macros
- **History View**: Review past days with daily averages and swipe-to-delete functionality

#### AI-Powered Food Recognition
- **Photo-Based Recognition**: Snap a photo of your food and let ML identify it from 100+ food classes
- **Confidence Scoring**: See prediction confidence and edit the food name if needed
- **USDA Integration**: Automatically searches USDA FoodData Central Survey (FNDDS) database using the predicted food name
- **Smart Workflow**: Photo → ML prediction → confirm/edit name → enter grams → USDA lookup → track macros

#### Food Dictionary
- **USDA Database**: Bundled with 300+ common foods from USDA FoodData Central
- **Manual Food Entry**: Add custom foods with full macro information
- **Barcode Scanner**: Scan product barcodes to add foods automatically
- **Meal Builder**: Combine multiple foods into reusable meals with automatic macro calculation
- **Ingredient Editor**: View and edit individual ingredients within saved meals
- **Favorites System**: Mark frequently used foods for quick access
- **Smart Search**: Filter by name, calories, favorites, or meals

#### Advanced Tracking
- **Flexible Serving Sizes**: Track by weight (grams/ml) or servings
- **Live Macro Preview**: See macros update in real-time as you adjust quantities
- **Hypothetical Tracking**: View what your totals would be before actually logging
- **Quick Track**: Rapidly log meals without detailed input
- **Food Log**: Review everything you've eaten today with edit/delete functionality

#### Meal Management
- **Weight Adjustment**: Manually adjust meal weight (e.g., after cooking reduces volume)
- **Ingredient Quantity Editing**: Modify ingredient amounts and see totals recalculate
- **Persistent Meal Updates**: Changes to meals are saved and reflected in future tracking
- **Meal History**: View foods eaten on any historical day

### Requirements

- **iOS**: 16.0+
- **Xcode**: 15.0+
- **macOS**: Monterey 12.0+ (for development)

### Installation & Setup

#### For Development

1. **Clone the repository**:
   ```bash
   cd "/Users/YOUR_USERNAME/Documents"
   git clone <repository-url> "Meal Tracker code"
   cd "Meal Tracker code"
   ```

2. **Open the Xcode project**:
   ```bash
   open FoodTrackingApp/FoodTrackingApp.xcodeproj
   ```

3. **Select your target device** (simulator or connected iPhone) in Xcode

4. **Build and run** (⌘R)

#### For TestFlight Beta

**TestFlight Link**
https://testflight.apple.com/join/1gzU61Ck

### USDA Food Database

The app includes a bundled default food library sourced from USDA FoodData Central. To regenerate or update the bundled defaults:

1. Get a [FoodData Central API key](https://fdc.nal.usda.gov/api-key-signup.html)

2. Set the API key in your terminal:
   ```bash
   export FDC_API_KEY="YOUR_KEY_HERE"
   ```

3. Run the generator script:
   ```bash
   cd "/Users/YOUR_USERNAME/Documents/Meal Tracker code"
   python3 tools/seed_usda_defaults.py \
     --queries tools/usda_queries_common.txt \
     --limit 300 \
     --data-types "Foundation,SR Legacy" \
     --mode overwrite \
     --out "FoodTrackingApp/FoodTrackingApp/default_all.json"
   ```

4. Rebuild the app to use the updated defaults

See [`tools/README.md`](tools/README.md) for more details on the generator script, including append/refresh modes and branded food support.

### Project Structure

```
FoodTrackingApp/
├── FoodTrackingApp/
│   ├── AppAndTheme/              # App entry & theming
│   │   ├── FoodTrackingAppApp.swift  # App entry point
│   │   ├── AppTheme.swift        # Theme colors & styling
│   │   └── ContentView.swift     # Root view (deprecated)
│   ├── Dictionary Info/          # Food dictionary & data models
│   │   ├── DictionaryView.swift  # Main food browsing interface
│   │   ├── FoodModel.swift       # Food data state management
│   │   ├── FoodStorage.swift     # Persistence layer
│   │   ├── AddFoodView.swift     # Manual food entry
│   │   ├── EditFoodItemView.swift # Food editor
│   │   ├── IngredientsView.swift # Meal ingredient editor
│   │   ├── MealBuilderView.swift # Meal composition interface
│   │   └── default_all.json      # Bundled USDA food defaults
│   ├── BarcodeScanner/           # Barcode scanning functionality
│   │   ├── BarcodeScannerView.swift
│   │   ├── ScannerViewController.swift
│   │   └── ...
│   ├── MachineLearning/          # AI food recognition
│   │   ├── FoodClassifier.mlpackage  # CoreML model (100+ food classes)
│   │   ├── FoodMLPredictor.swift     # ML inference wrapper
│   │   ├── ConfirmFoodNameAndGramsView.swift  # Confirmation UI
│   │   ├── ImagePicker.swift         # Photo capture
│   │   └── classes.txt               # Model class labels
│   ├── USDALookUp/               # USDA FoodData Central integration
│   │   ├── USDANutritionService.swift  # API client for Survey (FNDDS) lookup
│   │   └── FoodQueryType.swift
│   ├── Tracking/                 # Daily macro tracking
│   │   ├── MacroTrackerViewModel.swift  # Daily macro state & persistence
│   │   ├── GramsOrServingsInput.swift   # Quantity input with live preview
│   │   └── QuickTrackView.swift         # Fast macro entry
│   ├── MacroHistoryAndLogs/      # History & logging
│   │   ├── DailyMacrosDisplay.swift     # Visual macro ring display
│   │   ├── MacroHistoryView.swift       # History with daily averages
│   │   ├── FoodLogView.swift            # Today's food log
│   │   └── FoodLogViewForDate.swift     # Historical day view
│   ├── MacroGoals/               # Goal setting
│   │   ├── MacroGoalWizardView.swift    # Goal calculation wizard
│   │   └── EditGoalsView.swift          # Manual goal editor
│   └── MainMenu.swift            # Main tab navigation
└── tools/                        # USDA generator scripts
    ├── seed_usda_defaults.py     # USDA FoodData Central importer
    ├── usda_queries_common.txt   # Search queries for common foods
    └── README.md                 # Generator documentation
```

### Data Persistence

- **User Foods**: Stored in `user_foods.json` in the app's Documents directory
- **Daily Macros**: Persisted via `UserDefaults` and rolled over at midnight
- **History**: JSON-encoded array of daily macro entries with food logs
- **Goals**: Stored in `UserDefaults` (calories, protein, carbs, fats)

On first launch, the app seeds `user_foods.json` from the bundled `default_all.json`. Subsequent launches merge any updated bundled defaults without overwriting user-added foods.

### Key Technologies

- **SwiftUI**: Declarative UI framework
- **Combine**: Reactive state management
- **CoreML**: On-device food image recognition (100+ food classes)
- **AVFoundation**: Barcode scanning and photo capture
- **USDA FoodData Central API**: 
  - Build-time: Bundled defaults generation
  - Runtime: Live Survey (FNDDS) lookup for ML-recognized foods
- **UserDefaults**: Lightweight persistence for goals and state
- **FileManager**: JSON-based food dictionary storage

### Contributing

This is a personal project, but suggestions and feedback are welcome. The codebase is structured for maintainability with clear separation between data models, views, and business logic.

### Known Issues & Future Enhancements

- Widget support for glanceable macro tracking (in progress)
- Cloud sync for multi-device support
- Export/import functionality for data portability
- Meal planning features
- Recipe scaling based on servings


---

## Support

For bug reports or feature requests, please [open an issue](link-to-issues) or contact via TestFlight feedback.
