#!/usr/bin/env python3
"""Launcher icons (legacy + adaptive) and the 512 px Play Store icon from art/icon/*.png.

Run after scripts/make_art.py:  ~/tools/venvs/rhythm/bin/python scripts/make_icons.py
"""
import pathlib

from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parent.parent
RES = ROOT / "android" / "app" / "src" / "main" / "res"
DENS = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}

full = Image.open(ROOT / "art" / "icon" / "icon_full.png").convert("RGBA")
fg = Image.open(ROOT / "art" / "icon" / "icon_foreground.png").convert("RGBA")

for name, k in DENS.items():
    d = RES / f"mipmap-{name}"
    d.mkdir(parents=True, exist_ok=True)
    legacy = round(48 * k)
    # Legacy icon: rounded square so it looks right on launchers without adaptive support.
    icon = full.resize((legacy, legacy), Image.LANCZOS)
    mask = Image.new("L", (legacy, legacy), 0)
    from PIL import ImageDraw
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, legacy - 1, legacy - 1], radius=round(legacy * 0.2), fill=255)
    icon.putalpha(mask)
    icon.save(d / "ic_launcher.png")
    fg.resize((round(108 * k),) * 2, Image.LANCZOS).save(d / "ic_launcher_foreground.png")

v26 = RES / "mipmap-anydpi-v26"
v26.mkdir(exist_ok=True)
(v26 / "ic_launcher.xml").write_text("""<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
    <monochrome android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
""")
store = ROOT / "store-assets"
store.mkdir(exist_ok=True)
full.resize((512, 512), Image.LANCZOS).convert("RGB").save(store / "icon-512.png")
print("icons written")
