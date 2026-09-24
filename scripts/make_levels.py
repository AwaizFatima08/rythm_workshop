#!/usr/bin/env python3
"""Write the 12 level files (assets/levels/*.json) and index.json.

Level BPM must equal its music's BPM: the beat clock reads the music position.
Run:  python3 scripts/make_levels.py
"""
import json
import pathlib

OUT = pathlib.Path(__file__).resolve().parent.parent / "assets" / "levels"
MUSIC = {"bgm_calm.ogg": 70, "bgm_workshop_01.ogg": 80, "bgm_workshop_02.ogg": 90}
SYMBOL = {"red": "circle", "blue": "square", "yellow": "star", "green": "triangle"}
TOYS = ["car", "ball", "block", "duck"]
SIZE_TOYS = ["teddy", "drum", "boat", "rocket"]
FRUITS = ["apple", "banana", "grapes", "strawberry", "pear", "orange"]
VEGS = ["carrot", "broccoli", "corn", "eggplant", "peas", "potato"]


def colour_bins(cs):
    return [{"id": c, "symbol": SYMBOL[c], "image": f"bins/bin_{c}.png"} for c in cs]


def colour_items(cs):
    return [{"id": f"{t}_{c}", "bin": c, "image": f"items/{t}_{c}.png"} for c in cs for t in TOYS]


def size_items():
    return ([{"id": f"{t}_big", "bin": "big", "image": f"items/{t}.png", "scale": 1.0} for t in SIZE_TOYS]
            + [{"id": f"{t}_small", "bin": "small", "image": f"items/{t}.png", "scale": 0.58} for t in SIZE_TOYS])


def shape_items(kinds):
    return [{"id": f"{k}_{c}", "bin": k, "image": f"items/shape_{k}_{c}.png"} for k in kinds for c in SYMBOL]


def food_items():
    return ([{"id": f, "bin": "fruit", "image": f"items/{f}.png"} for f in FRUITS]
            + [{"id": v, "bin": "veg", "image": f"items/{v}.png"} for v in VEGS])


SIZE_BINS = [{"id": "big", "symbol": "big", "image": "bins/bin_big.png"},
             {"id": "small", "symbol": "small", "image": "bins/bin_small.png"}]
FOOD_BINS = [{"id": "fruit", "symbol": "apple", "image": "bins/bin_fruit.png"},
             {"id": "veg", "symbol": "carrot", "image": "bins/bin_veg.png"}]


def shape_bins(kinds):
    return [{"id": k, "symbol": k, "image": f"bins/bin_{k}.png"} for k in kinds]


def level(i, lid, world, sort_by, music, belt, count, prompt, bins, items, practice=False, spawn=4, max_on=3, **extra):
    return {"id": lid, "index": i, "world": world, "sortBy": sort_by, "music": music, "bpm": MUSIC[music],
            "beltSpeed": belt, "practiceTaps": practice, "voicePrompt": prompt, "spawnEveryBeats": spawn,
            "maxOnBelt": max_on, "itemCount": count, "bins": bins, "items": items, **extra}


LEVELS = [
    level(1, "colour_01", 1, "colour", "bgm_calm.ogg", 70, 10, "vo_prompt_colour", colour_bins(["red", "blue"]),
          colour_items(["red", "blue"]), practice=True, max_on=2),
    level(2, "colour_02", 1, "colour", "bgm_calm.ogg", 80, 10, "vo_prompt_colour", colour_bins(["red", "blue"]),
          colour_items(["red", "blue"])),
    level(3, "colour_03", 1, "colour", "bgm_calm.ogg", 80, 12, "vo_prompt_colour",
          colour_bins(["red", "blue", "yellow"]), colour_items(["red", "blue", "yellow"])),
    level(4, "size_01", 2, "size", "bgm_calm.ogg", 70, 10, "vo_prompt_size", SIZE_BINS, size_items(),
          practice=True, max_on=2),
    level(5, "size_02", 2, "size", "bgm_workshop_01.ogg", 85, 10, "vo_prompt_size", SIZE_BINS, size_items()),
    level(6, "size_03", 2, "size", "bgm_workshop_01.ogg", 90, 12, "vo_prompt_size", SIZE_BINS, size_items()),
    level(7, "shape_01", 3, "shape", "bgm_workshop_01.ogg", 80, 10, "vo_prompt_shape",
          shape_bins(["circle", "square"]), shape_items(["circle", "square"]), practice=True, max_on=2),
    level(8, "shape_02", 3, "shape", "bgm_workshop_01.ogg", 85, 12, "vo_prompt_shape",
          shape_bins(["circle", "square", "triangle"]), shape_items(["circle", "square", "triangle"])),
    level(9, "shape_03", 3, "shape", "bgm_workshop_01.ogg", 95, 12, "vo_prompt_shape",
          shape_bins(["circle", "square", "triangle"]), shape_items(["circle", "square", "triangle"])),
    level(10, "food_01", 4, "category", "bgm_workshop_01.ogg", 90, 10, "vo_prompt_food", FOOD_BINS, food_items()),
    level(11, "food_02", 4, "category", "bgm_workshop_02.ogg", 100, 12, "vo_prompt_food", FOOD_BINS, food_items()),
    level(12, "pattern_01", 4, "pattern", "bgm_workshop_02.ogg", 90, 10, "vo_prompt_pattern", FOOD_BINS, food_items(),
          pattern=["fruit", "veg"]),
]

if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    for lv in LEVELS:
        (OUT / f"{lv['id']}.json").write_text(json.dumps(lv, indent=2, ensure_ascii=False) + "\n")
    (OUT / "index.json").write_text(json.dumps({"levels": [lv["id"] for lv in LEVELS]}, indent=2) + "\n")
    print(f"wrote {len(LEVELS)} levels")
