# History search, weekday labels, and day header — design

Date: 2026-11-20 · Size: small change

## Why
- Cem wants to find when (and how much) he ate a given food, without scrolling through every day.
- History cards show "Nov 19, 2026" and the weekday isn't obvious.
- The day detail screen is titled "Daily Log" with no date or totals, so you lose context once you tap in.

## What gets built
1. **Search on History** (`MacroHistoryAndLogs/MacroHistoryView.swift`)
   - A custom text-field row directly below the Daily Average card (not `.searchable`, which can only sit under the nav title).
   - Case-insensitive substring match against `LoggedFoodEntry.food.name` only. Meals match by meal name; meal ingredients are **not** searched.
   - Empty query → all days, unchanged. Non-empty → only days with ≥1 matching food.
   - Each matching day card adds lines showing the matches, e.g. `🔎 Chicken breast · 200 g` (quantity in the entry's grams/servings mode). Up to 3 lines, then "+N more".
   - No matches → empty state: *No days with "xyz"*.
   - Daily Average always reflects **all** days, not the filtered set.
2. **Weekday on cards** — `HistoryDayRow` shows "Nov 17, 2026 · Monday".
3. **Day screen header** (`FoodLogViewForDate.swift`)
   - First list row (scrolls with the foods): date + weekday, plus the day's calories / protein / carbs / fats.
   - Totals come from the stored `MacroHistoryEntry` fields, so they always match the History card.
   - Call site passes the whole `MacroHistoryEntry` (only caller is `MacroHistoryView`).

## Approaches considered
- **Custom search row in the list (chosen)** — puts the bar where Cem asked, below the average card, and matches the app's styling.
- `.searchable` — rejected: it's fixed under the nav title, not below the card.
- Search index / storage changes — rejected: history is small, so filtering in memory is instant. No migration needed.

## Non-goals
- Searching today's in-progress log (it isn't in history until rollover).
- Searching meal ingredients.
- Changing what history stores.

## Constraints
- Follow the CLAUDE.md conventions: `.scaled` layout numbers, `AppTheme` colors/fonts, no `print`.
- No test target: verify with a build plus manual steps in the app.

## Left to the builder
- Exact styling of the search field and match lines, consistent with existing cards and pills.
- Weekday/date formatting via `Date.formatted` / `DateFormatter` (locale-aware).
