## Default foods generator (USDA FoodData Central)

This folder contains the helper that builds the bundled default food list shipped with the app. The curated food list lives inline in `seed_usda_defaults.py` as `CURATED_FOODS` — each entry is a `(friendly_name, search_query, preferred_source)` tuple.

### What it generates
- A JSON array of `FoodItem` objects (matching the Swift model) normalized to **per 100g**:
  - `weightInGrams = 100`, `servings = 1`, `servingUnit = "g"`
- Deterministic UUIDs derived from the friendly name (re-runs are stable per food).

### How sources are picked
Each food declares a preferred USDA source (`sr_legacy` or `survey`). The script walks a fallback chain per source:

| Preferred | Chain |
|---|---|
| `sr_legacy` | SR Legacy → Foundation → Survey (FNDDS) |
| `survey` | Survey (FNDDS) → SR Legacy → Foundation |

The chain also detects the "lettuce bug" — Foundation entries that report kcal=0 with nonzero protein/carbs/fat — and falls back when it sees that. As a result, lettuce returns its real ~14–17 kcal/100g instead of 0.

### How to run

```bash
export FDC_API_KEY="YOUR_KEY_HERE"
python3 tools/seed_usda_defaults.py \
  --out "FoodTrackingApp/FoodTrackingApp/Dictionary Info/default_all.json" \
  --log tools/build_log.csv
```

The build log (`build_log.csv`) records the source used, fdcId, USDA description, and macros for every entry. Eyeball it before shipping — anything that fell back to a non-preferred source is worth a second look.

### Adding or editing foods

Edit `CURATED_FOODS` in `seed_usda_defaults.py` and re-run. The script overwrites the output JSON each run.

### After running

Bump `bundledDefaultsVersion` in `FoodStorage.swift` and rebuild. The app's wipe-and-reseed migration will replace the existing dictionary on next launch.
