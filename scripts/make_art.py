#!/usr/bin/env python3
"""Draw every image in the app as SVG, then render PNGs with Inkscape.

Style: flat shapes, 6-unit walnut (#4A3728) outlines, the accessible palette from the
design (red/blue/green/yellow + symbols). SVG sources go to art/svg/, PNGs to assets/images/.
To swap in hand-made or Gemini art later, keep the same file name and pixel size.

Run:  python3 scripts/make_art.py      (needs Inkscape on PATH)
"""
import math
import pathlib
import subprocess

ROOT = pathlib.Path(__file__).resolve().parent.parent
SVG = ROOT / "art" / "svg"
IMG = ROOT / "assets" / "images"

WALNUT = "#4A3728"
CREAM = "#FFF4E0"
COLOURS = {  # id: (main, light, dark, symbol)
    "red": ("#C62828", "#E86A5E", "#8E1B1B", "circle"),
    "blue": ("#1E5AA8", "#5C8FD6", "#123C73", "square"),
    "yellow": ("#FFC107", "#FFE27A", "#D99A00", "star"),
    "green": ("#2E7D32", "#6DBA70", "#1B5E20", "triangle"),
}
WOOD, WOOD_DARK, WOOD_LIGHT = "#C98B4F", "#A0683A", "#E3B07A"
AMBER = "#F5A623"
S = f'stroke="{WALNUT}" stroke-width="6" stroke-linejoin="round" stroke-linecap="round"'
S4 = f'stroke="{WALNUT}" stroke-width="4" stroke-linejoin="round" stroke-linecap="round"'

JOBS = []  # (svg path, png path)


def save(rel, body, vb_w, vb_h, px_w, px_h=None):
    px_h = px_h or round(px_w * vb_h / vb_w)
    svg = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{px_w}" height="{px_h}" '
           f'viewBox="0 0 {vb_w} {vb_h}">{body}</svg>')
    src = SVG / f"{rel}.svg"
    src.parent.mkdir(parents=True, exist_ok=True)
    src.write_text(svg)
    # Icons are source art for scripts/make_icons.py, not app assets.
    out = (ROOT / "art" if rel.startswith("icon/") else IMG) / f"{rel}.png"
    out.parent.mkdir(parents=True, exist_ok=True)
    JOBS.append((src, out))


def star_path(cx, cy, r_out, r_in, n=5, rot=-90):
    pts = []
    for i in range(2 * n):
        r = r_out if i % 2 == 0 else r_in
        a = math.radians(rot + i * 180 / n)
        pts.append(f"{cx + r * math.cos(a):.1f},{cy + r * math.sin(a):.1f}")
    return "M" + " L".join(pts) + " Z"


def symbol(kind, cx, cy, r, fill, stroke=S4):
    """Shape symbol used on colour bins and toy badges (never colour alone)."""
    if kind == "circle":
        return f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="{fill}" {stroke}/>'
    if kind == "square":
        s = r * 1.7
        return f'<rect x="{cx - s / 2}" y="{cy - s / 2}" width="{s}" height="{s}" rx="{r * 0.2}" fill="{fill}" {stroke}/>'
    if kind == "star":
        return f'<path d="{star_path(cx, cy, r * 1.2, r * 0.55)}" fill="{fill}" {stroke}/>'
    if kind == "triangle":
        h = r * 1.9
        return (f'<path d="M{cx},{cy - h * 0.6} L{cx + h * 0.62},{cy + h * 0.45} L{cx - h * 0.62},{cy + h * 0.45} Z" '
                f'fill="{fill}" {stroke}/>')
    raise ValueError(kind)


def badge(colour):
    main, _, _, sym = COLOURS[colour]
    return (f'<circle cx="164" cy="164" r="30" fill="{CREAM}" {S4}/>' + symbol(sym, 164, 165, 15, main))


# --- toys (200 x 200) -----------------------------------------------------------

def car(c):
    m, l, d, _ = COLOURS[c]
    return f'''
<path d="M52,70 Q60,44 92,42 L122,42 Q146,44 154,70 Z" fill="{l}" {S}/>
<path d="M68,68 L76,52 L98,52 L98,68 Z M108,68 L108,52 L126,52 Q138,54 142,68 Z" fill="#DDF1FF" {S4}/>
<rect x="18" y="68" width="166" height="56" rx="22" fill="{m}" {S}/>
<rect x="30" y="80" width="40" height="10" rx="5" fill="{l}" opacity="0.8"/>
<circle cx="170" cy="92" r="7" fill="#FFE27A" {S4}/>
<circle cx="58" cy="128" r="24" fill="{WALNUT}"/><circle cx="58" cy="128" r="10" fill="#C9C0B6"/>
<circle cx="144" cy="128" r="24" fill="{WALNUT}"/><circle cx="144" cy="128" r="10" fill="#C9C0B6"/>'''


def ball(c):
    m, l, d, _ = COLOURS[c]
    return f'''
<circle cx="96" cy="100" r="74" fill="{m}" {S}/>
<path d="M30,76 Q96,118 166,76" fill="none" stroke="{CREAM}" stroke-width="16" stroke-linecap="round"/>
<path d="M36,132 Q96,164 160,130" fill="none" stroke="{CREAM}" stroke-width="12" stroke-linecap="round"/>
<ellipse cx="66" cy="60" rx="18" ry="11" fill="#FFFFFF" opacity="0.55" transform="rotate(-30 66 60)"/>
<circle cx="96" cy="100" r="74" fill="none" {S}/>'''


def block(c):
    m, l, d, _ = COLOURS[c]
    return f'''
<path d="M40,64 L78,30 L168,30 L130,64 Z" fill="{l}" {S}/>
<path d="M130,64 L168,30 L168,130 L130,166 Z" fill="{d}" {S}/>
<rect x="40" y="64" width="90" height="102" rx="6" fill="{m}" {S}/>
<rect x="56" y="80" width="58" height="70" rx="10" fill="none" stroke="{CREAM}" stroke-width="7" opacity="0.8"/>'''


def duck(c):
    m, l, d, _ = COLOURS[c]
    return f'''
<path d="M24,112 Q30,168 96,170 Q164,170 174,122 Q160,132 140,120 Q146,96 128,86 L60,108 Q40,112 24,112 Z" fill="{m}" {S}/>
<path d="M72,132 Q100,150 128,126" fill="none" stroke="{d}" stroke-width="7" stroke-linecap="round"/>
<circle cx="112" cy="70" r="40" fill="{m}" {S}/>
<path d="M146,70 Q176,66 184,80 Q170,94 146,88 Z" fill="{AMBER}" {S4}/>
<circle cx="120" cy="60" r="8" fill="{WALNUT}"/><circle cx="123" cy="57" r="3" fill="#FFF"/>
<ellipse cx="96" cy="50" rx="12" ry="7" fill="#FFFFFF" opacity="0.45" transform="rotate(-25 96 50)"/>'''


def teddy():
    return f'''
<circle cx="58" cy="44" r="22" fill="{WOOD}" {S}/><circle cx="142" cy="44" r="22" fill="{WOOD}" {S}/>
<circle cx="58" cy="44" r="10" fill="{WOOD_LIGHT}"/><circle cx="142" cy="44" r="10" fill="{WOOD_LIGHT}"/>
<ellipse cx="100" cy="146" rx="62" ry="48" fill="{WOOD}" {S}/>
<ellipse cx="100" cy="152" rx="34" ry="28" fill="{WOOD_LIGHT}"/>
<circle cx="46" cy="176" r="18" fill="{WOOD}" {S}/><circle cx="154" cy="176" r="18" fill="{WOOD}" {S}/>
<circle cx="100" cy="76" r="52" fill="{WOOD}" {S}/>
<ellipse cx="100" cy="94" rx="24" ry="18" fill="{WOOD_LIGHT}"/>
<ellipse cx="100" cy="86" rx="9" ry="6" fill="{WALNUT}"/>
<path d="M90,100 Q100,108 110,100" fill="none" {S4}/>
<circle cx="80" cy="68" r="7" fill="{WALNUT}"/><circle cx="120" cy="68" r="7" fill="{WALNUT}"/>
<path d="M78,122 L100,134 L122,122 L122,142 L100,132 L78,142 Z" fill="{COLOURS['blue'][0]}" {S4}/>'''


def toy_drum():
    return f'''
<path d="M36,70 L36,150 Q100,182 164,150 L164,70 Z" fill="{COLOURS['red'][0]}" {S}/>
<path d="M36,86 L64,150 L100,92 L136,150 L164,86" fill="none" stroke="{CREAM}" stroke-width="7" stroke-linejoin="round"/>
<ellipse cx="100" cy="70" rx="64" ry="22" fill="{CREAM}" {S}/>
<path d="M58,40 L96,64 M142,40 L108,62" {S} stroke-width="8"/>
<circle cx="56" cy="38" r="10" fill="{WOOD}" {S4}/><circle cx="144" cy="38" r="10" fill="{WOOD}" {S4}/>'''


def boat():
    return f'''
<path d="M104,20 L104,120" {S}/>
<path d="M110,26 Q150,70 162,112 L110,112 Z" fill="{CREAM}" {S}/>
<path d="M98,40 Q70,78 56,112 L98,112 Z" fill="{AMBER}" {S}/>
<path d="M22,124 L178,124 Q166,172 120,174 L76,174 Q34,172 22,124 Z" fill="{COLOURS['blue'][0]}" {S}/>
<circle cx="70" cy="146" r="8" fill="{CREAM}" {S4}/><circle cx="100" cy="146" r="8" fill="{CREAM}" {S4}/><circle cx="130" cy="146" r="8" fill="{CREAM}" {S4}/>'''


def rocket():
    return f'''
<path d="M100,14 Q146,52 140,126 L60,126 Q54,52 100,14 Z" fill="{CREAM}" {S}/>
<path d="M100,14 Q124,32 134,56 L66,56 Q76,32 100,14 Z" fill="{COLOURS['red'][0]}" {S}/>
<circle cx="100" cy="86" r="18" fill="#9ED3F5" {S}/>
<path d="M60,100 L30,146 L62,138 Z M140,100 L170,146 L138,138 Z" fill="{COLOURS['red'][0]}" {S}/>
<path d="M76,126 L124,126 L116,146 L84,146 Z" fill="{WALNUT}"/>
<path d="M86,150 Q100,196 114,150 Z" fill="{AMBER}" {S4}/>'''


def shape_block(kind, c):
    m, l, d, _ = COLOURS[c]
    if kind == "circle":
        return (f'<circle cx="100" cy="100" r="76" fill="{m}" {S}/><circle cx="100" cy="100" r="50" fill="none" '
                f'stroke="{l}" stroke-width="8"/><ellipse cx="72" cy="62" rx="16" ry="10" fill="#fff" opacity="0.45" '
                f'transform="rotate(-35 72 62)"/>')
    if kind == "square":
        return (f'<rect x="26" y="26" width="148" height="148" rx="14" fill="{m}" {S}/><rect x="50" y="50" width="100" '
                f'height="100" rx="8" fill="none" stroke="{l}" stroke-width="8"/>')
    return (f'<path d="M100,20 L182,168 L18,168 Z" fill="{m}" {S}/><path d="M100,64 L144,144 L56,144 Z" fill="none" '
            f'stroke="{l}" stroke-width="8" stroke-linejoin="round"/>')


FOOD = {
    "apple": f'''<path d="M100,56 Q140,30 168,70 Q186,130 140,172 Q120,184 100,172 Q80,184 60,172 Q14,130 32,70 Q60,30 100,56 Z" fill="#D32F2F" {S}/>
<path d="M100,56 Q98,34 110,18" fill="none" {S}/><path d="M108,34 Q134,14 152,30 Q130,50 108,34 Z" fill="#43A047" {S4}/>
<ellipse cx="62" cy="86" rx="12" ry="20" fill="#fff" opacity="0.4" transform="rotate(20 62 86)"/>''',
    "banana": f'''<path d="M36,60 Q40,150 120,164 Q164,168 176,146 Q120,150 88,118 Q60,90 60,52 Z" fill="#FFD54F" {S}/>
<path d="M60,52 L58,34 L42,36 L36,60" fill="#8D6E63" {S4}/><path d="M176,146 L186,150" {S}/>''',
    "grapes": f'''<path d="M100,40 Q104,24 116,16" fill="none" {S}/><path d="M104,32 Q132,14 146,34 Q124,46 104,32 Z" fill="#43A047" {S4}/>
''' + "".join(f'<circle cx="{x}" cy="{y}" r="21" fill="#7B3FA0" {S4}/>' for x, y in
              [(78, 62), (120, 62), (58, 96), (100, 96), (142, 96), (78, 130), (120, 130), (100, 162)]),
    "strawberry": f'''<path d="M100,178 Q30,130 34,80 Q40,50 100,54 Q160,50 166,80 Q170,130 100,178 Z" fill="#E53935" {S}/>
<path d="M60,54 L78,34 L90,50 L100,30 L110,50 L122,34 L140,54 Q100,70 60,54 Z" fill="#43A047" {S4}/>
''' + "".join(f'<ellipse cx="{x}" cy="{y}" rx="3" ry="5" fill="#FFE082"/>' for x, y in
              [(70, 88), (100, 84), (130, 88), (84, 112), (116, 112), (92, 138), (110, 158), (126, 134), (58, 110), (142, 110)]),
    "pear": f'''<path d="M100,40 Q124,40 126,80 Q170,110 158,150 Q146,184 100,182 Q54,184 42,150 Q30,110 74,80 Q76,40 100,40 Z" fill="#C0CA33" {S}/>
<path d="M100,40 Q100,24 108,14" fill="none" {S}/><path d="M104,28 Q126,10 142,26 Q124,40 104,28 Z" fill="#43A047" {S4}/>
<ellipse cx="72" cy="130" rx="10" ry="18" fill="#fff" opacity="0.35"/>''',
    "orange": f'''<circle cx="100" cy="106" r="72" fill="#FB8C00" {S}/>
<path d="M100,36 Q124,14 146,30 Q126,52 100,36 Z" fill="#43A047" {S4}/>
''' + "".join(f'<circle cx="{x}" cy="{y}" r="3" fill="#E65100"/>' for x, y in [(70, 90), (120, 80), (136, 120), (84, 132), (106, 110), (60, 120)]),
    "carrot": f'''<path d="M80,54 Q100,44 128,58 Q126,110 76,182 Q66,120 80,54 Z" fill="#FB8C00" transform="rotate(20 100 110)" {S}/>
<path d="M104,52 Q92,20 100,10 Q112,30 110,50 M112,52 Q132,22 146,24 Q136,44 116,56 M100,54 Q70,30 60,38 Q76,54 98,60" fill="#43A047" {S4}/>
<path d="M96,90 L110,92 M92,120 L104,122 M86,148 L96,150" {S4}/>''',
    "broccoli": f'''<path d="M84,110 L76,182 L124,182 L116,110 Z" fill="#9CCC65" {S}/>
''' + "".join(f'<circle cx="{x}" cy="{y}" r="{r}" fill="#2E7D32" {S4}/>' for x, y, r in
              [(60, 90, 30), (140, 90, 30), (100, 60, 36), (84, 104, 26), (118, 104, 26), (100, 94, 24)]),
    "corn": f'''<path d="M100,20 Q146,60 132,150 L68,150 Q54,60 100,20 Z" fill="#FFD54F" {S}/>
''' + "".join(f'<circle cx="{x}" cy="{y}" r="7" fill="#FFB300"/>' for x in (82, 100, 118) for y in (60, 84, 108, 132) if not (x != 100 and y == 60)) + f'''
<path d="M68,150 Q40,110 50,70 Q72,110 96,176 Z M132,150 Q160,110 150,70 Q128,110 104,176 Z" fill="#7CB342" {S}/>''',
    "eggplant": f'''<path d="M118,56 Q170,80 160,140 Q150,186 96,180 Q36,172 50,120 Q60,84 118,56 Z" fill="#6A1B9A" {S}/>
<path d="M104,62 Q112,40 136,40 Q150,56 140,74 Q124,64 104,62 Z" fill="#43A047" {S4}/><path d="M132,44 L144,22" {S}/>
<ellipse cx="80" cy="128" rx="10" ry="22" fill="#fff" opacity="0.3" transform="rotate(30 80 128)"/>''',
    "peas": f'''<path d="M20,120 Q60,60 170,70 Q182,72 180,84 Q140,150 30,136 Q16,132 20,120 Z" fill="#7CB342" {S}/>
''' + "".join(f'<circle cx="{x}" cy="{y}" r="15" fill="#AED581" {S4}/>' for x, y in [(56, 112), (88, 104), (120, 98), (150, 90)]),
    "potato": f'''<path d="M40,90 Q50,46 110,48 Q172,52 170,110 Q166,158 104,160 Q34,160 40,90 Z" fill="#C8A165" {S}/>
''' + "".join(f'<circle cx="{x}" cy="{y}" r="4" fill="#8D6E63"/>' for x, y in [(78, 84), (120, 76), (140, 118), (96, 124), (66, 124)]),
}
FRUITS = ["apple", "banana", "grapes", "strawberry", "pear", "orange"]
VEGS = ["carrot", "broccoli", "corn", "eggplant", "peas", "potato"]


def make_items():
    for c in ("red", "blue", "yellow"):
        for name, fn in (("car", car), ("ball", ball), ("block", block), ("duck", duck)):
            save(f"items/{name}_{c}", fn(c) + badge(c), 200, 200, 320)
    for name, fn in (("teddy", teddy), ("drum", toy_drum), ("boat", boat), ("rocket", rocket)):
        save(f"items/{name}", fn(), 200, 200, 320)
    for kind in ("circle", "square", "triangle"):
        for c in COLOURS:
            save(f"items/shape_{kind}_{c}", shape_block(kind, c), 200, 200, 320)
    for name, body in FOOD.items():
        save(f"items/{name}", body, 200, 200, 320)


# --- bins (250 x 200) -------------------------------------------------------------

def crate(panel, plaque):
    return f'''
<path d="M14,40 L236,40 L224,70 L26,70 Z" fill="{WOOD_DARK}" {S}/>
<path d="M22,62 L228,62 L214,190 L36,190 Z" fill="{panel}" {S}/>
<path d="M30,100 L220,100 M34,140 L216,140" stroke="{WALNUT}" stroke-width="3" opacity="0.25"/>
<rect x="8" y="48" width="234" height="22" rx="10" fill="{WOOD}" {S}/>
<circle cx="125" cy="128" r="50" fill="{CREAM}" {S}/>
{plaque}'''


def make_bins():
    for c, (m, l, d, sym) in COLOURS.items():
        save(f"bins/bin_{c}", crate(m, symbol(sym, 125, 128, 30, m, S)), 250, 200, 500)
    save("bins/bin_big", crate(WOOD, f'<rect x="93" y="96" width="64" height="64" rx="8" fill="{WALNUT}"/>'), 250, 200, 500)
    save("bins/bin_small", crate(WOOD, f'<rect x="113" y="116" width="24" height="24" rx="4" fill="{WALNUT}"/>'), 250, 200, 500)
    for kind in ("circle", "square", "triangle"):
        save(f"bins/bin_{kind}", crate(WOOD, symbol(kind, 125, 130, 28, "none",
                                                    f'stroke="{WALNUT}" stroke-width="10" stroke-linejoin="round"')),
             250, 200, 500)
    save("bins/bin_fruit", crate("#E9A23B", f'<g transform="translate(88 92) scale(0.36)">{FOOD["apple"]}</g>'
                                            f'<g transform="translate(120 100) scale(0.32)">{FOOD["banana"]}</g>'), 250, 200, 500)
    save("bins/bin_veg", crate("#8BB35A", f'<g transform="translate(84 92) scale(0.36)">{FOOD["carrot"]}</g>'
                                          f'<g transform="translate(122 96) scale(0.34)">{FOOD["broccoli"]}</g>'), 250, 200, 500)


# --- characters -----------------------------------------------------------------------

PIP_NAVY, PIP_WING = "#2C3E5C", "#223149"
WING = "M0,0 Q-34,58 -8,112 Q20,72 14,4 Z"


def pip(left=15, right=15, tilt=0, eyes="open", extra="", behind=()):
    """Wings rotate about the shoulders (+ = outward). Wings named in `behind` are drawn behind the body."""
    def wing(x, r, mirror):
        m = "scale(-1,1) " if mirror else ""
        return f'<path d="{WING}" transform="translate({x},176) {m}rotate({r})" fill="{PIP_WING}" {S}/>'
    if eyes == "open":
        eye = "".join(f'<ellipse cx="{x}" cy="140" rx="21" ry="24" fill="#fff" {S4}/><circle cx="{x + 3}" cy="144" r="11" '
                      f'fill="{WALNUT}"/><circle cx="{x + 7}" cy="138" r="4" fill="#fff"/>' for x in (118, 182))
    elif eyes == "happy":
        eye = "".join(f'<path d="M{x - 16},146 Q{x},124 {x + 16},146" fill="none" {S}/>' for x in (118, 182))
    else:  # closed
        eye = "".join(f'<path d="M{x - 16},140 Q{x},154 {x + 16},140" fill="none" {S}/>' for x in (118, 182))
    return f'''<g transform="translate(50 0) rotate({tilt} 150 330)">
<ellipse cx="116" cy="336" rx="32" ry="14" fill="{AMBER}" {S}/><ellipse cx="184" cy="336" rx="32" ry="14" fill="{AMBER}" {S}/>
{wing(56, left, False) if "l" in behind else ""}{wing(244, right, True) if "r" in behind else ""}
<path d="M150,50 Q262,54 260,210 Q256,332 150,334 Q44,332 40,210 Q38,54 150,50 Z" fill="{PIP_NAVY}" {S}/>
<path d="M150,120 Q226,124 222,232 Q218,312 150,314 Q82,312 78,232 Q74,124 150,120 Z" fill="#FFFDF7"/>
<path d="M146,52 Q138,28 156,20 Q150,36 162,44" fill="{PIP_NAVY}" {S4}/>
{eye}
<ellipse cx="96" cy="178" rx="14" ry="9" fill="#F48FB1" opacity="0.8"/><ellipse cx="204" cy="178" rx="14" ry="9" fill="#F48FB1" opacity="0.8"/>
<path d="M128,166 Q150,154 172,166 Q150,194 128,166 Z" fill="{AMBER}" {S4}/>
{wing(56, left, False) if "l" not in behind else ""}{wing(244, right, True) if "r" not in behind else ""}
{extra}</g>'''


def zz(x, y, s):
    return (f'<path d="M{x},{y} l{s},0 l-{s},{s} l{s},0" fill="none" stroke="{PIP_NAVY}" stroke-width="{s / 5:.1f}" '
            f'stroke-linecap="round" stroke-linejoin="round"/>')


def make_pip():
    poses = {
        "pip_idle": pip(),
        "pip_clap": pip(-55, -55, eyes="happy"),
        "pip_point": pip(15, 100),
        "pip_wave": pip(15, 150, eyes="happy"),
        "pip_hmm": pip(-75, 15, tilt=-8),
        "pip_dance": pip(140, 140, eyes="happy"),
        "pip_sleep": pip(-20, -20, eyes="closed", extra=zz(236, 40, 26) + zz(268, 6, 18), behind="lr"),
    }
    for name, body in poses.items():
        save(f"characters/{name}", body, 400, 360, 440)


MILO_BROWN, MILO_FACE = "#8D5A3B", "#EFCFA6"


def milo(lh, rh, mouth="smile"):
    """lh/rh: hand positions. Arms are drawn as round-capped strokes with an outline."""
    def arm(sx, sy, hx, hy):
        mx, my = (sx + hx) / 2 + (-14 if hx < 160 else 14), (sy + hy) / 2
        d = f"M{sx},{sy} Q{mx},{my} {hx},{hy}"
        return (f'<path d="{d}" fill="none" stroke="{WALNUT}" stroke-width="32" stroke-linecap="round"/>'
                f'<path d="{d}" fill="none" stroke="{MILO_BROWN}" stroke-width="22" stroke-linecap="round"/>'
                f'<circle cx="{hx}" cy="{hy}" r="16" fill="{MILO_FACE}" {S4}/>')
    mouths = {
        "smile": f'<path d="M140,142 Q160,160 180,142" fill="none" {S}/>',
        "open": f'<path d="M138,138 Q160,176 182,138 Z" fill="#B23A3A" {S4}/>',
    }
    drums = f'''
<path d="M58,262 L68,330 L152,330 L162,262 Z" fill="{WOOD}" {S}/><path d="M60,284 L160,284" stroke="{COLOURS['red'][0]}" stroke-width="12"/>
<ellipse cx="110" cy="262" rx="54" ry="16" fill="{CREAM}" {S}/>
<path d="M170,266 L178,330 L246,330 L254,266 Z" fill="{WOOD_DARK}" {S}/><path d="M172,288 L252,288" stroke="{COLOURS['blue'][0]}" stroke-width="12"/>
<ellipse cx="212" cy="266" rx="44" ry="14" fill="{CREAM}" {S}/>'''
    return f'''
<path d="M226,236 Q296,236 290,170 Q286,130 256,140 Q274,150 272,176 Q268,212 222,212" fill="{MILO_BROWN}" {S}/>
<ellipse cx="160" cy="220" rx="80" ry="72" fill="{MILO_BROWN}" {S}/>
<ellipse cx="160" cy="232" rx="48" ry="46" fill="{MILO_FACE}"/>
{drums}
{arm(100, 196, *lh)}{arm(220, 196, *rh)}
<circle cx="86" cy="104" r="26" fill="{MILO_BROWN}" {S}/><circle cx="86" cy="104" r="14" fill="{MILO_FACE}"/>
<circle cx="234" cy="104" r="26" fill="{MILO_BROWN}" {S}/><circle cx="234" cy="104" r="14" fill="{MILO_FACE}"/>
<circle cx="160" cy="108" r="72" fill="{MILO_BROWN}" {S}/>
<circle cx="138" cy="104" r="30" fill="{MILO_FACE}"/><circle cx="182" cy="104" r="30" fill="{MILO_FACE}"/>
<ellipse cx="160" cy="136" rx="46" ry="30" fill="{MILO_FACE}"/>
<ellipse cx="140" cy="100" rx="11" ry="13" fill="{WALNUT}"/><ellipse cx="180" cy="100" rx="11" ry="13" fill="{WALNUT}"/>
<circle cx="143" cy="96" r="4" fill="#fff"/><circle cx="183" cy="96" r="4" fill="#fff"/>
<circle cx="154" cy="126" r="3.5" fill="{WALNUT}"/><circle cx="166" cy="126" r="3.5" fill="{WALNUT}"/>
{mouths[mouth]}
<path d="M144,40 Q160,22 170,42" fill="none" {S}/>'''


def make_milo():
    poses = {
        "milo_idle": milo((110, 238), (212, 242)),
        "milo_hit_left": milo((110, 258), (236, 188)),
        "milo_hit_right": milo((84, 188), (212, 262)),
        "milo_celebrate": milo((60, 60), (260, 60), "open"),
    }
    for name, body in poses.items():
        save(f"characters/{name}", body, 320, 340, 384)


# --- background, world cards, icon -----------------------------------------------------

def background():
    planks = "".join(f'<rect x="{x}" y="0" width="160" height="720" fill="{"#FBEBD0" if i % 2 else CREAM}"/>'
                     f'<path d="M{x},0 L{x},720" stroke="#EBD3AE" stroke-width="3"/>' for i, x in enumerate(range(0, 1600, 160)))
    shelf = lambda x, y, w: (f'<rect x="{x}" y="{y}" width="{w}" height="18" rx="6" fill="{WOOD}" {S}/>'
                             f'<path d="M{x + 20},{y + 18} l14,30 M{x + w - 20},{y + 18} l-14,30" {S}/>')
    decor = (shelf(40, 470, 260) + f'<g transform="translate(60 380) scale(0.45)">{ball("blue")}</g>'
             f'<g transform="translate(160 390) scale(0.4)">{block("yellow")}</g>' + shelf(1300, 470, 260)
             + f'<g transform="translate(1320 380) scale(0.45)">{toy_drum()}</g>'
             f'<g transform="translate(1440 386) scale(0.42)">{duck("red")}</g>')
    window = (f'<rect x="690" y="420" width="220" height="150" rx="16" fill="#CFE8F7" {S}/>'
              f'<path d="M800,420 L800,570 M690,495 L910,495" {S}/><circle cx="740" cy="455" r="18" fill="#FFE27A"/>')
    notes = "".join(f'<g transform="translate({x} {y}) rotate({r})" opacity="0.35"><ellipse cx="0" cy="30" rx="14" ry="10" '
                    f'fill="{AMBER}"/><path d="M12,30 L12,-10 L30,-4" fill="none" stroke="{AMBER}" stroke-width="6" '
                    f'stroke-linecap="round"/></g>' for x, y, r in [(420, 470, -10), (1120, 450, 12), (560, 600, 8), (1000, 610, -6)])
    floor = (f'<rect x="0" y="720" width="1600" height="180" fill="{WOOD_LIGHT}"/>'
             f'<path d="M0,720 L1600,720" stroke="{WOOD_DARK}" stroke-width="8"/>'
             + "".join(f'<path d="M{x},730 L{x - 60},900" stroke="{WOOD}" stroke-width="4"/>' for x in range(100, 1700, 200)))
    save("ui/background", planks + window + decor + notes + floor, 1600, 900, 1600)


def card(inner, accent):
    return (f'<rect x="8" y="8" width="284" height="224" rx="28" fill="#FFFDF7" stroke="{accent}" stroke-width="12"/>'
            f'<rect x="8" y="8" width="284" height="224" rx="28" fill="none" stroke="{WALNUT}" stroke-width="4"/>' + inner)


def g(body, x, y, s):
    return f'<g transform="translate({x} {y}) scale({s})">{body}</g>'


def make_worlds():
    save("worlds/world_1", card(g(ball("red") + badge("red"), 30, 50, 0.62) + g(block("blue") + badge("blue"), 150, 60, 0.6)
                                , COLOURS["red"][0]), 300, 240, 450)
    save("worlds/world_2", card(g(teddy(), 22, 30, 0.9) + g(teddy(), 186, 120, 0.44), COLOURS["blue"][0]), 300, 240, 450)
    save("worlds/world_3", card(g(shape_block("circle", "yellow"), 22, 74, 0.45) + g(shape_block("square", "green"), 110, 74, 0.45)
                                + g(shape_block("triangle", "red"), 194, 70, 0.45), COLOURS["green"][0]), 300, 240, 450)
    basket = (f'<path d="M50,140 L250,140 L226,216 L74,216 Z" fill="{WOOD}" {S}/>'
              f'<path d="M70,160 L230,160 M78,186 L222,186" stroke="{WOOD_DARK}" stroke-width="6"/>')
    save("worlds/world_4", card(g(FOOD["apple"], 60, 58, 0.5) + g(FOOD["banana"], 130, 50, 0.5) + g(FOOD["carrot"], 180, 60, 0.45)
                                + basket, AMBER), 300, 240, 450)


def make_icon():
    notes = (f'<g transform="translate(330 70) rotate(12)"><ellipse cx="0" cy="60" rx="24" ry="17" fill="{WALNUT}"/>'
             f'<path d="M20,60 L20,0 L52,10" fill="none" stroke="{WALNUT}" stroke-width="10" stroke-linecap="round"/></g>')
    pip_small = g(pip(15, 150, eyes="happy"), 48, 70, 0.95)
    # Legacy square icon (512) and Play store icon.
    save("icon/icon_full", f'<rect width="512" height="512" fill="{AMBER}"/><circle cx="256" cy="300" r="190" fill="#FFD27A"/>'
                           + pip_small + notes, 512, 512, 1024)
    # Adaptive-icon foreground: content kept inside the central 66% safe zone.
    save("icon/icon_foreground", f'<g transform="translate(97 97) scale(0.62)">{pip_small}{notes}</g>', 512, 512, 432)


def render():
    # Inkscape exports each SVG at its width/height attributes; batch in groups for speed.
    for i in range(0, len(JOBS), 25):
        chunk = JOBS[i:i + 25]
        subprocess.run(["inkscape", "--export-type=png", "--export-overwrite", *[str(s) for s, _ in chunk]],
                       check=True, capture_output=True)
        for src, out in chunk:
            src.with_suffix(".png").replace(out)


if __name__ == "__main__":
    make_items()
    make_bins()
    make_pip()
    make_milo()
    background()
    make_worlds()
    make_icon()
    render()
    print(f"rendered {len(JOBS)} images")
