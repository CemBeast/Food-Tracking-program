# Session Tradeoff

## What Was Done

### App code (complete, ready to build)
- **`USDANutritionService.swift`** — added `USDAFoodDetails` struct with `servingSizeG` and `isLiquid`. New public method `fetchFoodDetailsForFood(fdcId:)` fetches macros + real serving size from USDA in one call. `fetchMacrosPer100gForFood` (used for search previews) still works unchanged.
- **`LookUpFoodView.swift`** — `selectChoice()` now calls `fetchFoodDetailsForFood`, scales macros by `servingG / 100`, and sets `weightInGrams = servingG` (falls back to 100g if USDA has no serving data).
- **`FoodStorage.swift`** — bumped `bundledDefaultsVersion` from `3` → `4`. This forces a full wipe-and-reseed of every user's dictionary on next launch.

### Script (`tools/seed_usda_defaults.py`) — partially working
- Added `fetch_food_details(api_key, fdc_id)` — GET `/food/{fdcId}`, returns `{}` on any error (no crash).
- Added `get_serving_size_g(details)` — checks `servingSize`/`servingSizeUnit` first (Branded), then `foodPortions[0].gramWeight` (SR Legacy / Survey). Falls back to 100g.
- `FetchResult` now carries `serving_g` and `is_liquid`.
- `build_food_item` scales all macros by `serving_g / 100` and sets `weightInGrams = int(serving_g)`.

---

## What Still Needs to Be Done

### 1. Fix `default_all.json` — the critical blocker
The script exits with code 2 (partial run). Current state of `default_all.json`: **84 foods written**, most with correct serving sizes, but the file is incomplete.

**Root cause:** ~30 foods in `CURATED_FOODS` return 404 from USDA search across all three data type fallbacks. These are the failing foods (from the last run's failure list):
- Sauerkraut, Kimchi, Pizza (Cheese & Pepperoni), Mac & Cheese, Lasagna, Pancakes, Waffles, French Toast, Donut, Blueberry Muffin, Chocolate Chip Cookie, Dark/Milk Chocolate, Vanilla/Chocolate Ice Cream, Potato/Tortilla Chips, Pretzels, Popcorn, Saltine Crackers, Granola Bar, OJ, Almond Milk, Soy Milk, Whey Protein, Coffee, Black/Green Tea, Cola, Feta Cheese, Orange, Strawberries, Raspberries, Blackberries, Grapes, Cantaloupe, Mango.

**Fix options (pick one):**
- A) Update the search queries in `CURATED_FOODS` for the failing foods to match current USDA naming
- B) Add a `--retry` flag with exponential backoff (some 404s may be transient rate limiting)
- C) Add a third fallback: if all searches fail, keep the old entry from the previous `default_all.json`

### 2. Verify serving sizes are sane
Some serving sizes look suspicious (e.g., 441g — possibly Lentils matched a large Survey portion). After a clean run, spot-check foods in the log (`tools/build_log.csv`) and fix any outliers.

### 3. Run the script to completion
```bash
cd "/Users/cem/Documents/Personal Stuff/Meal Tracker code"
FDC_API_KEY="t0BsvWaxrul3XFuFpst0nmsu7m1iYIvMdikLzgqa"  # from Secrets.xcconfig
python3 tools/seed_usda_defaults.py \
  --out "FoodTrackingApp/FoodTrackingApp/Dictionary Info/default_all.json" \
  --log tools/build_log.csv \
  --sleep-ms 300
```

### 4. Build and test in Xcode
- Build → confirm no compile errors
- Launch fresh sim (or delete app) to trigger v4 reseed
- Check that egg, banana, chicken breast etc. show realistic serving sizes

---

## Key Files
| File | Location |
|------|----------|
| USDA service | `FoodTrackingApp/USDALookUp/USDANutritionService.swift` |
| Food lookup view | `FoodTrackingApp/Dictionary Info/LookUpFoodView.swift` |
| Version constant | `FoodTrackingApp/Dictionary Info/FoodStorage.swift` → `bundledDefaultsVersion = 4` |
| Seed script | `tools/seed_usda_defaults.py` |
| API key | `Secrets.xcconfig` → `FDC_API_KEY` |
| Build log | `tools/build_log.csv` (generated after script run) |
