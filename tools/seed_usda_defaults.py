#!/usr/bin/env python3
"""
Generate a bundled default food library from USDA FoodData Central (FDC).

Output JSON matches the app's FoodItem Codable shape:
  - id (UUID string)
  - name
  - weightInGrams (100; per-100g normalization)
  - servings (1)
  - calories (kcal)
  - protein/carbs/fats (grams)
  - servingUnit ("g")

Usage:
  FDC_API_KEY="..." python3 tools/seed_usda_defaults.py --out "FoodTrackingApp/FoodTrackingApp/default_all.json"

Notes:
  - This script is intended to be run by you during development to refresh the
    bundled defaults JSON. Do not ship the API key in the app.
"""

from __future__ import annotations

import argparse
import json
import os
import time
import uuid
from dataclasses import dataclass
from typing import Any, Dict, List, Optional
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen


FDC_BASE = "https://api.nal.usda.gov/fdc/v1"

# Nutrient IDs (FoodData Central)
NUTRIENT_ENERGY_KCAL = 1008
NUTRIENT_PROTEIN_G = 1003
NUTRIENT_CARBS_G = 1005
NUTRIENT_FAT_G = 1004


@dataclass(frozen=True)
class Macros:
    calories: int
    protein: float
    carbs: float
    fats: float


def _http_json(method: str, url: str, body: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
    data = None
    headers = {"Accept": "application/json"}
    if body is not None:
        data = json.dumps(body).encode("utf-8")
        headers["Content-Type"] = "application/json"
    req = Request(url=url, data=data, headers=headers, method=method)
    with urlopen(req, timeout=30) as resp:
        raw = resp.read()
    return json.loads(raw.decode("utf-8"))


def fdc_search(api_key: str, query: str, data_types: List[str], page_size: int = 5) -> List[Dict[str, Any]]:
    url = f"{FDC_BASE}/foods/search?api_key={api_key}"
    body = {
        "query": query,
        "pageSize": page_size,
        "pageNumber": 1,
        "dataType": data_types,
    }
    payload = _http_json("POST", url, body)
    return payload.get("foods", []) or []


def extract_macros(food: Dict[str, Any]) -> Optional[Macros]:
    """
    Try to extract calories/protein/carbs/fats from a FoodData Central search result.
    Values are typically per 100g for Foundation/SR.
    """
    nutrients = food.get("foodNutrients") or []
    by_id: Dict[int, float] = {}
    for n in nutrients:
        nid = n.get("nutrientId")
        val = n.get("value")
        if isinstance(nid, int) and isinstance(val, (int, float)):
            by_id[nid] = float(val)

    if NUTRIENT_ENERGY_KCAL not in by_id:
        return None

    calories = int(round(by_id.get(NUTRIENT_ENERGY_KCAL, 0.0)))
    protein = float(by_id.get(NUTRIENT_PROTEIN_G, 0.0))
    carbs = float(by_id.get(NUTRIENT_CARBS_G, 0.0))
    fats = float(by_id.get(NUTRIENT_FAT_G, 0.0))

    # Basic sanity
    if calories <= 0 and protein == 0 and carbs == 0 and fats == 0:
        return None

    return Macros(calories=calories, protein=protein, carbs=carbs, fats=fats)


def stable_uuid_for_fdc_id(fdc_id: int) -> str:
    # Deterministic UUID so defaults can be merged by ID across updates.
    u = uuid.uuid5(uuid.NAMESPACE_URL, f"usda-fdc:{fdc_id}")
    return str(u).upper()


def normalize_name(s: str) -> str:
    s = (s or "").strip()
    return " ".join(s.split())


def build_food_item(fdc_food: Dict[str, Any]) -> Optional[Dict[str, Any]]:
    fdc_id = fdc_food.get("fdcId")
    if not isinstance(fdc_id, int):
        return None

    name = normalize_name(fdc_food.get("description") or fdc_food.get("lowercaseDescription") or "")
    if not name:
        return None

    macros = extract_macros(fdc_food)
    if macros is None:
        return None

    return {
        "id": stable_uuid_for_fdc_id(fdc_id),
        "name": name.title(),
        "weightInGrams": 100,
        "servings": 1,
        "calories": macros.calories,
        "protein": round(macros.protein, 2),
        "carbs": round(macros.carbs, 2),
        "fats": round(macros.fats, 2),
        "servingUnit": "g",
    }

def load_existing_items(path: str) -> List[Dict[str, Any]]:
    try:
        with open(path, "r", encoding="utf-8") as f:
            data = json.load(f)
        if isinstance(data, list):
            return [x for x in data if isinstance(x, dict)]
        return []
    except FileNotFoundError:
        return []
    except json.JSONDecodeError:
        return []


def merge_items(
    *,
    existing: List[Dict[str, Any]],
    generated: List[Dict[str, Any]],
    mode: str,
) -> List[Dict[str, Any]]:
    """
    mode:
      - overwrite: return generated
      - append: add missing by id; keep existing items
      - refresh: replace by id if present; also add missing
    """
    if mode == "overwrite":
        return generated

    by_id: Dict[str, Dict[str, Any]] = {}
    name_to_id: Dict[str, str] = {}

    for item in existing:
        item_id = str(item.get("id") or "").upper()
        if not item_id:
            continue
        by_id[item_id] = item
        nm = str(item.get("name") or "").strip().lower()
        if nm:
            name_to_id[nm] = item_id

    for item in generated:
        item_id = str(item.get("id") or "").upper()
        if not item_id:
            continue

        if item_id in by_id:
            if mode == "refresh":
                by_id[item_id] = item
            continue

        # In append/refresh, avoid duplicates by name too (non-meals). Defaults file is non-meals.
        nm = str(item.get("name") or "").strip().lower()
        if nm and nm in name_to_id:
            if mode == "refresh":
                # replace the existing item with the same name
                existing_id = name_to_id[nm]
                by_id[existing_id] = item
            continue

        by_id[item_id] = item
        if nm:
            name_to_id[nm] = item_id

    merged = list(by_id.values())
    merged.sort(key=lambda x: str(x.get("name") or "").lower())
    return merged


def load_queries(path: Optional[str], limit: int) -> List[str]:
    if path is None:
        # Minimal starter list; replace with a larger curated file for ~300 foods.
        base = [
            "apple raw",
            "banana raw",
            "chicken breast roasted",
            "white rice cooked",
            "olive oil",
            "whole milk",
            "egg whole raw",
            "broccoli raw",
            "oats",
            "salmon atlantic cooked",
        ]
        return base[:limit]

    with open(path, "r", encoding="utf-8") as f:
        lines = [ln.strip() for ln in f.readlines()]
    queries = [ln for ln in lines if ln and not ln.startswith("#")]
    return queries[:limit]


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", required=True, help="Output JSON path (e.g. FoodTrackingApp/FoodTrackingApp/default_all.json)")
    ap.add_argument("--queries", default=None, help="Optional text file of search queries (one per line)")
    ap.add_argument("--limit", type=int, default=300, help="Max number of foods to include")
    ap.add_argument(
        "--mode",
        choices=["overwrite", "append", "refresh"],
        default="overwrite",
        help="Write mode: overwrite file, append missing, or refresh existing by id",
    )
    ap.add_argument(
        "--data-types",
        default="Foundation,SR Legacy",
        help="Comma-separated FDC dataType list (e.g. Foundation,SR Legacy,Branded)",
    )
    ap.add_argument("--sleep-ms", type=int, default=120, help="Delay between API calls (rate limiting)")
    args = ap.parse_args()

    api_key = os.environ.get("FDC_API_KEY", "").strip()
    if not api_key:
        raise SystemExit("Missing FDC_API_KEY env var.")

    data_types = [x.strip() for x in args.data_types.split(",") if x.strip()]
    queries = load_queries(args.queries, args.limit)

    out_items: List[Dict[str, Any]] = []
    seen_names: set[str] = set()

    for q in queries:
        try:
            foods = fdc_search(api_key=api_key, query=q, data_types=data_types, page_size=5)
        except (HTTPError, URLError) as e:
            print(f"[WARN] search failed for {q!r}: {e}")
            continue

        picked: Optional[Dict[str, Any]] = None
        for cand in foods:
            item = build_food_item(cand)
            if item is None:
                continue
            key = item["name"].lower()
            if key in seen_names:
                continue
            picked = item
            break

        if picked is None:
            print(f"[WARN] no usable result for {q!r}")
            continue

        out_items.append(picked)
        seen_names.add(picked["name"].lower())
        print(f"[OK] {picked['name']} ({picked['calories']} kcal / 100g)")

        time.sleep(max(0, args.sleep_ms) / 1000.0)

        if len(out_items) >= args.limit:
            break

    out_items.sort(key=lambda x: x["name"].lower())

    # Merge with existing file if requested
    existing_items = load_existing_items(args.out)
    final_items = merge_items(existing=existing_items, generated=out_items, mode=args.mode)

    os.makedirs(os.path.dirname(args.out), exist_ok=True)
    with open(args.out, "w", encoding="utf-8") as f:
        json.dump(final_items, f, indent=2, ensure_ascii=False)
        f.write("\n")

    print(f"✅ Wrote {len(final_items)} foods to {args.out} (mode={args.mode})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

