## Default foods generator (USDA FoodData Central)

This folder contains helper tooling to generate the bundled default food list used by the app on first launch.

### What it generates
- A JSON array of `FoodItem` objects (matching your Swift model) normalized to **per 100g**:
  - `weightInGrams = 100`
  - `servings = 1`
  - `servingUnit = "g"`
- Deterministic UUIDs derived from USDA `fdcId` so later updates can merge by ID.

### How to run
1. Get a FoodData Central API key and set it in your shell:

```bash
export FDC_API_KEY="YOUR KEY HERE"
```

2. Run the generator:

```bash
python3 tools/seed_usda_defaults.py \
  --queries tools/usda_queries_common.txt \
  --limit 300 \
  --data-types "Foundation,SR Legacy" \
  --out "FoodTrackingApp/FoodTrackingApp/default_all.json"
```

3. Rebuild / reinstall the app. On first launch (or when `user_foods.json` is missing), the app will seed the user dictionary from the bundled `default_all.json`.

### Notes
- Do not ship your `FDC_API_KEY` inside the iOS app.
- For “fast food” / branded items later, you can rerun with `--data-types "Branded"` and a queries list containing restaurant items.

