#!/usr/bin/env python3
"""Play Store feature graphic (1024x500) drawn from the app's own art.

Run:  python3 scripts/make_store_assets.py   (after make_art.py; needs Inkscape and the Andika font)
"""
import pathlib
import subprocess

ROOT = pathlib.Path(__file__).resolve().parent.parent
IMG = ROOT / "assets" / "images"
OUT = ROOT / "store-assets"


def href(rel):
    return (IMG / rel).as_uri()


svg = f'''<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="1024" height="500" viewBox="0 0 1024 500">
<image xlink:href="{href('ui/background.png')}" x="-60" y="-40" width="1144" height="644" preserveAspectRatio="xMidYMax slice"/>
<rect x="0" y="0" width="1024" height="500" fill="#FFF4E0" opacity="0.25"/>
<rect x="-10" y="250" width="1044" height="92" rx="12" fill="#6B5645" stroke="#4A3728" stroke-width="5"/>
<image xlink:href="{href('items/car_red.png')}" x="120" y="222" width="120" height="120"/>
<image xlink:href="{href('items/duck_blue.png')}" x="300" y="222" width="120" height="120"/>
<image xlink:href="{href('items/ball_yellow.png')}" x="610" y="222" width="120" height="120"/>
<image xlink:href="{href('items/apple.png')}" x="800" y="222" width="120" height="120"/>
<image xlink:href="{href('characters/milo_celebrate.png')}" x="30" y="330" width="170" height="170"/>
<image xlink:href="{href('characters/pip_wave.png')}" x="800" y="318" width="200" height="182"/>
<image xlink:href="{href('bins/bin_red.png')}" x="300" y="370" width="160" height="128"/>
<image xlink:href="{href('bins/bin_blue.png')}" x="560" y="370" width="160" height="128"/>
<text x="512" y="118" text-anchor="middle" font-family="Andika" font-weight="700" font-size="84" fill="#4A3728"
      stroke="#FFF4E0" stroke-width="14" paint-order="stroke" stroke-linejoin="round">Rhythm Workshop</text>
<text x="512" y="182" text-anchor="middle" font-family="Andika" font-weight="700" font-size="34" fill="#1E5AA8"
      stroke="#FFF4E0" stroke-width="10" paint-order="stroke" stroke-linejoin="round">Sort toys to the beat</text>
</svg>'''
OUT.mkdir(exist_ok=True)
src = ROOT / "art" / "svg" / "feature-graphic.svg"
src.write_text(svg)
subprocess.run(["inkscape", str(src), "--export-type=png", f"--export-filename={OUT / 'feature-graphic-1024x500.png'}",
                "--export-background=#FFF4E0", "--export-background-opacity=1"], check=True, capture_output=True)
print("feature graphic written")
