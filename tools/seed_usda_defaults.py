#!/usr/bin/env python3
"""
Generate the bundled default food library from USDA FoodData Central (FDC).

Each entry in CURATED_FOODS is (friendly_name, search_query, preferred_source).
The script tries the preferred source first, then walks a fallback chain. It
also detects the "lettuce bug" — Foundation entries that report kcal=0 with
nonzero protein/carbs/fat — and falls back when it sees that.

Output JSON matches the app's FoodItem Codable shape, normalized per 100g:
  id, name, weightInGrams=100, servings=1, calories, protein, carbs, fats,
  servingUnit="g"

Usage:
  FDC_API_KEY="..." python3 tools/seed_usda_defaults.py \
    --out "FoodTrackingApp/FoodTrackingApp/Dictionary Info/default_all.json" \
    --log tools/build_log.csv
"""

from __future__ import annotations

import argparse
import csv
import json
import os
import sys
import time
import uuid
from dataclasses import dataclass
from typing import Any, Dict, List, Optional, Tuple
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen


FDC_BASE = "https://api.nal.usda.gov/fdc/v1"

NUTRIENT_ENERGY_KCAL = 1008
NUTRIENT_PROTEIN_G = 1003
NUTRIENT_CARBS_G = 1005
NUTRIENT_FAT_G = 1004

# Source tags map to USDA dataType values, with a fallback chain per source.
SOURCE_CHAINS = {
    "sr_legacy": ["SR Legacy", "Foundation", "Survey (FNDDS)"],
    "survey":    ["Survey (FNDDS)", "SR Legacy", "Foundation"],
    "foundation": ["Foundation", "SR Legacy", "Survey (FNDDS)"],
}

# Curated food list. Each entry: (friendly_name, search_query, preferred_source)
# - sr_legacy: prefer for raw/whole single ingredients (complete macros)
# - survey:    prefer for cooked/prepared dishes (FNDDS coverage)
CURATED_FOODS: List[Tuple[str, str, str]] = [
    # ----- FRUITS (raw) -----
    ("Apple, Raw", "apples raw with skin", "sr_legacy"),
    ("Banana, Raw", "bananas raw", "sr_legacy"),
    ("Orange, Raw", "oranges raw all commercial varieties", "sr_legacy"),
    ("Mandarin Orange, Raw", "tangerines mandarin oranges raw", "sr_legacy"),
    ("Strawberries, Raw", "strawberries raw", "sr_legacy"),
    ("Blueberries, Raw", "blueberries raw", "sr_legacy"),
    ("Raspberries, Raw", "raspberries raw", "sr_legacy"),
    ("Blackberries, Raw", "blackberries raw", "sr_legacy"),
    ("Grapes, Raw", "grapes red or green european raw", "sr_legacy"),
    ("Pineapple, Raw", "pineapple raw all varieties", "sr_legacy"),
    ("Watermelon, Raw", "watermelon raw", "sr_legacy"),
    ("Cantaloupe, Raw", "melons cantaloupe raw", "sr_legacy"),
    ("Honeydew Melon, Raw", "melons honeydew raw", "sr_legacy"),
    ("Mango, Raw", "mangos raw", "sr_legacy"),
    ("Peach, Raw", "peaches raw", "sr_legacy"),
    ("Pear, Raw", "pears raw", "sr_legacy"),
    ("Cherries, Sweet, Raw", "cherries sweet raw", "sr_legacy"),
    ("Plum, Raw", "plums raw", "sr_legacy"),
    ("Kiwi, Raw", "kiwifruit green raw", "sr_legacy"),
    ("Avocado, Raw", "avocados raw all commercial varieties", "sr_legacy"),
    ("Pomegranate, Raw", "pomegranates raw", "sr_legacy"),
    ("Dates, Medjool", "dates medjool", "sr_legacy"),
    ("Raisins", "raisins seedless", "sr_legacy"),
    ("Lemon, Raw", "lemons raw without peel", "sr_legacy"),
    ("Lime, Raw", "limes raw", "sr_legacy"),

    # ----- VEGETABLES -----
    ("Broccoli, Raw", "broccoli raw", "sr_legacy"),
    ("Broccoli, Steamed", "broccoli cooked boiled drained without salt", "sr_legacy"),
    ("Spinach, Raw", "spinach raw", "sr_legacy"),
    ("Spinach, Cooked", "spinach cooked boiled drained without salt", "sr_legacy"),
    ("Kale, Raw", "kale raw", "sr_legacy"),
    ("Romaine Lettuce, Raw", "lettuce cos or romaine raw", "sr_legacy"),
    ("Iceberg Lettuce, Raw", "lettuce iceberg raw", "sr_legacy"),
    ("Arugula, Raw", "arugula raw", "sr_legacy"),
    ("Carrots, Raw", "carrots raw", "sr_legacy"),
    ("Baby Carrots, Raw", "carrots baby raw", "sr_legacy"),
    ("Celery, Raw", "celery raw", "sr_legacy"),
    ("Cucumber, Raw", "cucumber with peel raw", "sr_legacy"),
    ("Tomato, Raw", "tomatoes red ripe raw year round average", "sr_legacy"),
    ("Cherry Tomato, Raw", "tomatoes grape raw", "sr_legacy"),
    ("Red Bell Pepper, Raw", "peppers sweet red raw", "sr_legacy"),
    ("Green Bell Pepper, Raw", "peppers sweet green raw", "sr_legacy"),
    ("Yellow Bell Pepper, Raw", "peppers sweet yellow raw", "sr_legacy"),
    ("Onion, Raw", "onions raw", "sr_legacy"),
    ("White Mushrooms, Raw", "mushrooms white raw", "sr_legacy"),
    ("Zucchini, Raw", "squash summer zucchini includes skin raw", "sr_legacy"),
    ("Eggplant, Raw", "eggplant raw", "sr_legacy"),
    ("Asparagus, Raw", "asparagus raw", "sr_legacy"),
    ("Asparagus, Cooked", "asparagus cooked boiled drained without salt", "sr_legacy"),
    ("Brussels Sprouts, Raw", "brussels sprouts raw", "sr_legacy"),
    ("Brussels Sprouts, Cooked", "brussels sprouts cooked boiled drained without salt", "sr_legacy"),
    ("Cauliflower, Raw", "cauliflower raw", "sr_legacy"),
    ("Cabbage, Raw", "cabbage raw", "sr_legacy"),
    ("Sweet Potato, Baked", "sweet potato cooked baked in skin without salt", "sr_legacy"),
    ("Russet Potato, Baked", "potatoes baked flesh and skin without salt", "sr_legacy"),
    ("Corn, Sweet, Cooked", "corn sweet yellow cooked boiled drained without salt", "sr_legacy"),
    ("Green Beans, Cooked", "beans snap green cooked boiled drained without salt", "sr_legacy"),
    ("Peas, Green, Cooked", "peas green cooked boiled drained without salt", "sr_legacy"),
    ("Beets, Cooked", "beets cooked boiled drained", "sr_legacy"),

    # ----- GRAINS & STARCHES -----
    ("White Rice, Cooked", "rice white long grain regular cooked unenriched without salt", "sr_legacy"),
    ("Brown Rice, Cooked", "rice brown long grain cooked", "sr_legacy"),
    ("Quinoa, Cooked", "quinoa cooked", "sr_legacy"),
    ("Oatmeal, Cooked", "oats regular and quick cooked with water without salt", "sr_legacy"),
    ("Oats, Dry", "oats regular and quick not fortified dry", "sr_legacy"),
    ("Pasta, Cooked", "pasta cooked unenriched without added salt", "sr_legacy"),
    ("White Bread", "bread white commercially prepared", "sr_legacy"),
    ("Whole Wheat Bread", "bread whole wheat commercially prepared", "sr_legacy"),
    ("Sourdough Bread", "bread french or vienna includes sourdough", "sr_legacy"),
    ("Bagel, Plain", "bagels plain enriched with calcium propionate", "sr_legacy"),
    ("English Muffin", "muffins english plain enriched", "sr_legacy"),
    ("Flour Tortilla", "tortillas ready to bake or fry flour refrigerated", "sr_legacy"),
    ("Corn Tortilla", "tortillas ready to bake or fry corn", "sr_legacy"),
    ("Pita, White", "bread pita white enriched", "sr_legacy"),
    ("Naan", "bread naan plain commercially prepared refrigerated", "sr_legacy"),
    ("Rice Cake, Plain", "rice cake cracker", "sr_legacy"),
    ("French Fries", "potatoes french fried all types salt added in processing frozen oven heated", "survey"),
    ("Mashed Potatoes", "potatoes mashed home prepared whole milk and butter added", "survey"),

    # ----- POULTRY -----
    ("Chicken Breast, Raw", "chicken broilers or fryers breast skinless boneless meat only raw", "sr_legacy"),
    ("Chicken Breast, Grilled", "chicken broilers or fryers breast skinless boneless meat only cooked grilled", "sr_legacy"),
    ("Chicken Thigh, Cooked", "chicken broilers or fryers thigh meat only cooked roasted", "sr_legacy"),
    ("Chicken Wing, Cooked", "chicken broilers or fryers wing meat only cooked roasted", "sr_legacy"),
    ("Rotisserie Chicken", "chicken roasting meat and skin cooked roasted", "sr_legacy"),
    ("Ground Turkey, Raw", "turkey ground raw", "sr_legacy"),
    ("Ground Turkey, Cooked", "turkey ground cooked", "sr_legacy"),
    ("Turkey Breast, Deli", "turkey breast pre basted meat and skin cooked roasted", "sr_legacy"),
    ("Turkey Bacon, Cooked", "turkey breakfast sausage mild cooked", "sr_legacy"),

    # ----- BEEF / PORK -----
    ("Ground Beef 90/10, Cooked", "beef ground 90 lean meat 10 fat patty cooked broiled", "sr_legacy"),
    ("Ground Beef 80/20, Cooked", "beef ground 80 lean meat 20 fat patty cooked broiled", "sr_legacy"),
    ("Sirloin Steak, Cooked", "beef top sirloin steak boneless lean only cooked grilled", "sr_legacy"),
    ("Ribeye Steak, Cooked", "beef rib eye steak boneless lean only choice cooked grilled", "sr_legacy"),
    ("Hamburger Patty, Cooked", "beef ground 85 lean meat 15 fat patty cooked broiled", "sr_legacy"),
    ("Pork Loin Chop, Cooked", "pork fresh loin top loin chops boneless separable lean only cooked broiled", "sr_legacy"),
    ("Pork Tenderloin, Cooked", "pork fresh tenderloin separable lean only cooked roasted", "sr_legacy"),
    ("Bacon, Cooked", "pork cured bacon cooked pan fried", "sr_legacy"),
    ("Ham, Deli", "ham sliced regular approximately 11 percent fat", "sr_legacy"),
    ("Hot Dog, Beef", "frankfurter beef heated", "sr_legacy"),
    ("Pepperoni", "pepperoni beef and pork sliced", "sr_legacy"),
    ("Pork Sausage, Cooked", "pork sausage fresh cooked", "sr_legacy"),

    # ----- FISH / SEAFOOD -----
    ("Salmon, Cooked", "fish salmon atlantic farmed cooked dry heat", "sr_legacy"),
    ("Tuna, Canned in Water", "fish tuna light canned in water drained solids", "sr_legacy"),
    ("Tilapia, Cooked", "fish tilapia cooked dry heat", "sr_legacy"),
    ("Cod, Cooked", "fish cod atlantic cooked dry heat", "sr_legacy"),
    ("Shrimp, Cooked", "crustaceans shrimp cooked", "sr_legacy"),
    ("Sardines, Canned in Oil", "fish sardine atlantic canned in oil drained solids with bone", "sr_legacy"),
    ("Halibut, Cooked", "fish halibut atlantic and pacific cooked dry heat", "sr_legacy"),
    ("Scallops, Cooked", "mollusks scallop bay and sea cooked steamed", "sr_legacy"),

    # ----- EGGS & DAIRY -----
    ("Egg, Whole, Raw", "egg whole raw fresh", "sr_legacy"),
    ("Egg, Whole, Hard-Boiled", "egg whole cooked hard boiled", "sr_legacy"),
    ("Egg, Whole, Scrambled", "egg whole cooked scrambled", "sr_legacy"),
    ("Egg, Whole, Fried", "egg whole cooked fried", "sr_legacy"),
    ("Egg Whites, Raw", "egg white raw fresh", "sr_legacy"),
    ("Whole Milk", "milk whole 3.25 milkfat with added vitamin d", "sr_legacy"),
    ("2% Milk", "milk reduced fat fluid 2 milkfat with added vitamin a and vitamin d", "sr_legacy"),
    ("Skim Milk", "milk nonfat fluid with added vitamin a and vitamin d fat free or skim", "sr_legacy"),
    ("Heavy Cream", "cream fluid heavy whipping", "sr_legacy"),
    ("Butter, Salted", "butter salted", "sr_legacy"),
    ("Greek Yogurt, Whole Milk, Plain", "yogurt greek plain whole milk", "sr_legacy"),
    ("Greek Yogurt, Nonfat, Plain", "yogurt greek plain nonfat", "sr_legacy"),
    ("Cottage Cheese", "cheese cottage creamed large or small curd", "sr_legacy"),
    ("Cream Cheese", "cheese cream", "sr_legacy"),

    # ----- CHEESES -----
    ("Cheddar Cheese", "cheese cheddar", "sr_legacy"),
    ("Mozzarella, Whole Milk", "cheese mozzarella whole milk", "sr_legacy"),
    ("Parmesan, Grated", "cheese parmesan grated", "sr_legacy"),
    ("Swiss Cheese", "cheese swiss", "sr_legacy"),
    ("Feta Cheese", "cheese feta", "sr_legacy"),
    ("Provolone Cheese", "cheese provolone", "sr_legacy"),
    ("American Cheese", "cheese pasteurized process american fortified with vitamin d", "sr_legacy"),

    # ----- PLANT PROTEINS -----
    ("Tofu, Firm", "tofu raw firm prepared with calcium sulfate", "sr_legacy"),
    ("Tempeh, Cooked", "tempeh cooked", "sr_legacy"),
    ("Edamame, Cooked", "edamame frozen prepared", "sr_legacy"),
    ("Black Beans, Cooked", "beans black mature seeds cooked boiled without salt", "sr_legacy"),
    ("Chickpeas, Cooked", "chickpeas mature seeds cooked boiled without salt", "sr_legacy"),
    ("Lentils, Cooked", "lentils mature seeds cooked boiled without salt", "sr_legacy"),
    ("Kidney Beans, Cooked", "beans kidney all types mature seeds cooked boiled without salt", "sr_legacy"),
    ("Pinto Beans, Cooked", "beans pinto mature seeds cooked boiled without salt", "sr_legacy"),
    ("Refried Beans, Canned", "beans refried canned traditional style", "sr_legacy"),

    # ----- NUTS & SEEDS -----
    ("Almonds", "nuts almonds", "sr_legacy"),
    ("Walnuts", "nuts walnuts english", "sr_legacy"),
    ("Cashews", "nuts cashew nuts raw", "sr_legacy"),
    ("Pistachios", "nuts pistachio nuts dry roasted with salt added", "sr_legacy"),
    ("Peanuts, Roasted", "peanuts all types dry roasted with salt", "sr_legacy"),
    ("Pecans", "nuts pecans", "sr_legacy"),
    ("Sunflower Seeds", "seeds sunflower seed kernels dry roasted with salt added", "sr_legacy"),
    ("Pumpkin Seeds", "seeds pumpkin and squash seed kernels roasted with salt added", "sr_legacy"),
    ("Chia Seeds", "seeds chia seeds dried", "sr_legacy"),
    ("Flax Seeds", "seeds flaxseed", "sr_legacy"),

    # ----- OILS, FATS, SPREADS -----
    ("Olive Oil", "oil olive salad or cooking", "sr_legacy"),
    ("Avocado Oil", "oil avocado", "sr_legacy"),
    ("Canola Oil", "oil canola", "sr_legacy"),
    ("Peanut Butter", "peanut butter smooth style with salt", "sr_legacy"),
    ("Almond Butter", "nuts almond butter plain without salt added", "sr_legacy"),
    ("Honey", "honey", "sr_legacy"),
    ("Maple Syrup", "syrups maple", "sr_legacy"),
    ("Strawberry Jam", "jams and preserves", "sr_legacy"),

    # ----- CONDIMENTS / SAUCES -----
    ("Ketchup", "catsup", "sr_legacy"),
    ("Yellow Mustard", "mustard prepared yellow", "sr_legacy"),
    ("Dijon Mustard", "mustard prepared dijon", "survey"),
    ("Mayonnaise", "salad dressing mayonnaise regular with salt", "sr_legacy"),
    ("Soy Sauce", "soy sauce made from soy and wheat shoyu", "sr_legacy"),
    ("Hot Sauce", "sauce hot chile sriracha", "sr_legacy"),
    ("Worcestershire Sauce", "sauce worcestershire", "sr_legacy"),
    ("Ranch Dressing", "salad dressing ranch dressing regular", "sr_legacy"),
    ("Italian Dressing", "salad dressing italian dressing commercial regular", "sr_legacy"),
    ("Salsa", "sauce salsa ready to serve", "sr_legacy"),
    ("Guacamole", "avocado dip guacamole", "survey"),
    ("Hummus", "hummus commercial", "sr_legacy"),

    # ----- SIDES / PICKLES -----
    ("Pickles, Dill", "pickles cucumber dill or kosher dill", "sr_legacy"),
    ("Olives, Black", "olives ripe canned small extra large mammoth", "sr_legacy"),
    ("Sauerkraut", "sauerkraut", "sr_legacy"),
    ("Kimchi", "kimchi", "survey"),

    # ----- PREPARED DISHES (USDA Survey) -----
    ("Pizza, Cheese", "pizza cheese regular crust frozen cooked", "survey"),
    ("Pizza, Pepperoni", "pizza pepperoni regular crust frozen cooked", "survey"),
    ("Macaroni and Cheese", "macaroni or noodles with cheese", "survey"),
    ("Lasagna with Meat", "lasagna with meat", "survey"),
    ("Pancakes", "pancakes plain prepared from recipe", "survey"),
    ("Waffles", "waffles plain frozen ready to heat toasted", "survey"),
    ("French Toast", "french toast prepared from recipe made with low fat 2 milk", "survey"),
    ("Donut, Glazed", "doughnuts yeast leavened glazed enriched includes honey buns", "sr_legacy"),
    ("Blueberry Muffin", "muffins blueberry commercially prepared", "sr_legacy"),
    ("Chocolate Chip Cookie", "cookies chocolate chip commercially prepared regular higher fat enriched", "sr_legacy"),

    # ----- SNACKS / SWEETS -----
    ("Dark Chocolate", "candies chocolate dark 70 85 cacao solids", "sr_legacy"),
    ("Milk Chocolate", "candies milk chocolate", "sr_legacy"),
    ("Vanilla Ice Cream", "ice creams vanilla", "sr_legacy"),
    ("Chocolate Ice Cream", "ice creams chocolate", "sr_legacy"),
    ("Potato Chips", "snacks potato chips plain salted", "sr_legacy"),
    ("Tortilla Chips", "snacks tortilla chips plain", "sr_legacy"),
    ("Pretzels", "snacks pretzels hard plain salted", "sr_legacy"),
    ("Popcorn, Air-Popped", "snacks popcorn air popped", "sr_legacy"),
    ("Saltine Crackers", "crackers saltines includes oyster soda soup", "sr_legacy"),
    ("Granola Bar", "snacks granola bars hard plain", "sr_legacy"),

    # ----- BEVERAGES -----
    ("Orange Juice", "orange juice raw", "sr_legacy"),
    ("Almond Milk, Unsweetened", "beverages almond milk unsweetened shelf stable", "sr_legacy"),
    ("Soy Milk, Unsweetened", "beverages soy milk unsweetened with added calcium vitamins a and d", "sr_legacy"),
    ("Whey Protein Powder", "beverages whey protein powder isolate", "sr_legacy"),
    ("Brewed Coffee, Black", "beverages coffee brewed prepared with tap water", "sr_legacy"),
    ("Black Tea, Brewed", "beverages tea black brewed prepared with tap water", "sr_legacy"),
    ("Green Tea, Brewed", "beverages tea green brewed regular", "sr_legacy"),
    ("Cola", "beverages carbonated cola regular", "sr_legacy"),
]


@dataclass(frozen=True)
class Macros:
    calories: int
    protein: float
    carbs: float
    fats: float


@dataclass(frozen=True)
class FetchResult:
    fdc_id: int
    usda_description: str
    data_type: str
    macros: Macros


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


def fdc_search(api_key: str, query: str, data_type: str, page_size: int = 5) -> List[Dict[str, Any]]:
    url = f"{FDC_BASE}/foods/search?api_key={api_key}"
    body = {
        "query": query,
        "pageSize": page_size,
        "pageNumber": 1,
        "dataType": [data_type],
    }
    payload = _http_json("POST", url, body)
    return payload.get("foods", []) or []


def extract_macros(food: Dict[str, Any]) -> Optional[Macros]:
    nutrients = food.get("foodNutrients") or []
    by_id: Dict[int, float] = {}
    for n in nutrients:
        nid = n.get("nutrientId")
        val = n.get("value")
        if isinstance(nid, int) and isinstance(val, (int, float)):
            by_id[nid] = float(val)

    calories = int(round(by_id.get(NUTRIENT_ENERGY_KCAL, 0.0)))
    protein = float(by_id.get(NUTRIENT_PROTEIN_G, 0.0))
    carbs = float(by_id.get(NUTRIENT_CARBS_G, 0.0))
    fats = float(by_id.get(NUTRIENT_FAT_G, 0.0))

    if calories == 0 and protein == 0 and carbs == 0 and fats == 0:
        return None

    return Macros(calories=calories, protein=protein, carbs=carbs, fats=fats)


def is_likely_missing_kcal(m: Macros) -> bool:
    """Lettuce-bug detector: kcal=0 with nonzero protein/carbs/fat."""
    return m.calories == 0 and (m.protein > 0 or m.carbs > 0 or m.fats > 0)


def fetch_with_fallback(api_key: str, query: str, source: str, sleep_ms: int) -> Optional[FetchResult]:
    """Walk the source's fallback chain. Skip results with the lettuce bug
    unless this is the last source in the chain (then accept whatever we got)."""
    chain = SOURCE_CHAINS.get(source) or SOURCE_CHAINS["sr_legacy"]
    last_resort: Optional[FetchResult] = None

    for i, data_type in enumerate(chain):
        try:
            foods = fdc_search(api_key, query, data_type, page_size=5)
        except (HTTPError, URLError) as e:
            print(f"  [WARN] {data_type} search failed: {e}", file=sys.stderr)
            continue

        for cand in foods:
            macros = extract_macros(cand)
            if macros is None:
                continue
            result = FetchResult(
                fdc_id=int(cand.get("fdcId") or 0),
                usda_description=str(cand.get("description") or ""),
                data_type=data_type,
                macros=macros,
            )
            if is_likely_missing_kcal(macros):
                # Save as last resort and try next source
                last_resort = last_resort or result
                continue
            time.sleep(max(0, sleep_ms) / 1000.0)
            return result

        time.sleep(max(0, sleep_ms) / 1000.0)

    return last_resort


def stable_uuid_for_friendly_name(name: str) -> str:
    return str(uuid.uuid5(uuid.NAMESPACE_URL, f"foodtrackingapp:default:{name}")).upper()


def build_food_item(friendly_name: str, result: FetchResult) -> Dict[str, Any]:
    return {
        "id": stable_uuid_for_friendly_name(friendly_name),
        "name": friendly_name,
        "weightInGrams": 100,
        "servings": 1,
        "calories": result.macros.calories,
        "protein": round(result.macros.protein, 2),
        "carbs": round(result.macros.carbs, 2),
        "fats": round(result.macros.fats, 2),
        "servingUnit": "g",
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", required=True, help="Output JSON path")
    ap.add_argument("--log", default=None, help="Optional CSV log path for review")
    ap.add_argument("--sleep-ms", type=int, default=120, help="Delay between API calls")
    ap.add_argument("--limit", type=int, default=0, help="Limit foods processed (0 = all)")
    args = ap.parse_args()

    api_key = os.environ.get("FDC_API_KEY", "").strip()
    if not api_key:
        raise SystemExit("Missing FDC_API_KEY env var.")

    foods_to_process = CURATED_FOODS if args.limit <= 0 else CURATED_FOODS[: args.limit]
    items: List[Dict[str, Any]] = []
    log_rows: List[Dict[str, Any]] = []
    failures: List[str] = []

    for i, (friendly_name, query, source) in enumerate(foods_to_process, start=1):
        print(f"[{i}/{len(foods_to_process)}] {friendly_name}  (query={query!r}, source={source})")
        result = fetch_with_fallback(api_key, query, source, args.sleep_ms)

        if result is None:
            print(f"  [FAIL] no result")
            failures.append(friendly_name)
            log_rows.append({
                "friendly_name": friendly_name, "query": query, "preferred_source": source,
                "source_used": "", "fdc_id": "", "usda_description": "",
                "kcal": "", "protein": "", "carbs": "", "fats": "", "warnings": "no result",
            })
            continue

        item = build_food_item(friendly_name, result)
        items.append(item)
        warnings = []
        if is_likely_missing_kcal(result.macros):
            warnings.append("kcal=0 lettuce-bug (used as last resort)")
        print(f"  [OK] {result.data_type} fdc={result.fdc_id}  {item['calories']} kcal | "
              f"P{item['protein']} C{item['carbs']} F{item['fats']}")
        log_rows.append({
            "friendly_name": friendly_name, "query": query, "preferred_source": source,
            "source_used": result.data_type, "fdc_id": result.fdc_id,
            "usda_description": result.usda_description,
            "kcal": item["calories"], "protein": item["protein"],
            "carbs": item["carbs"], "fats": item["fats"],
            "warnings": "; ".join(warnings),
        })

    items.sort(key=lambda x: x["name"].lower())

    os.makedirs(os.path.dirname(args.out), exist_ok=True)
    with open(args.out, "w", encoding="utf-8") as f:
        json.dump(items, f, indent=2, ensure_ascii=False)
        f.write("\n")
    print(f"\nWrote {len(items)} foods to {args.out}")

    if args.log:
        os.makedirs(os.path.dirname(args.log) or ".", exist_ok=True)
        with open(args.log, "w", encoding="utf-8", newline="") as f:
            writer = csv.DictWriter(f, fieldnames=[
                "friendly_name", "query", "preferred_source", "source_used",
                "fdc_id", "usda_description", "kcal", "protein", "carbs", "fats", "warnings",
            ])
            writer.writeheader()
            writer.writerows(log_rows)
        print(f"Wrote build log to {args.log}")

    if failures:
        print(f"\n{len(failures)} failed lookups (review and adjust queries):")
        for name in failures:
            print(f"  - {name}")
        return 2

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
