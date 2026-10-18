#!/usr/bin/env python3
"""Draws the app icon for the installable web app (web/icon-*.png): a hook
in a cave ceiling, the rope and the swinging figure, pixel style.

    python3 tools/gen_icon.py

The picture stays inside the middle 80 %, so it also works as a maskable
icon (Android crops it to a circle or squircle).
"""
from pathlib import Path

from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parent.parent / "web"
S = 64  # drawn small, scaled up with nearest filter for the pixel look
BG = (10, 9, 13)
GOLD = (232, 197, 71)
ROCK = (66, 58, 52)
ROCK_DARK = (40, 35, 32)
ICE = (150, 210, 240)

img = Image.new("RGB", (S, S), BG)
d = ImageDraw.Draw(img)
# Cave ceiling with stalactites, a glow of crystals on the walls.
d.rectangle([7, 8, 56, 13], fill=ROCK)
for x, length in ((12, 6), (20, 3), (44, 5), (51, 8)):
    d.polygon([(x - 2, 14), (x + 2, 14), (x, 14 + length)], fill=ROCK_DARK)
d.rectangle([7, 8, 10, 52], fill=ROCK)
d.rectangle([53, 8, 56, 52], fill=ROCK)
d.polygon([(11, 40), (14, 36), (14, 44)], fill=ICE)
d.polygon([(52, 30), (49, 26), (49, 34)], fill=ICE)
# Hook in the ceiling, taut rope, figure in mid-swing.
d.polygon([(29, 14), (35, 14), (32, 18)], fill=(210, 210, 220))
d.line([(32, 17), (42, 38)], fill=GOLD, width=2)
d.ellipse([40, 36, 46, 42], fill=(237, 189, 148))
d.rounded_rectangle([39, 42, 47, 51], radius=2, fill=(184, 56, 41))
d.line([(41, 51), (38, 55)], fill=(40, 50, 90), width=2)
d.line([(45, 51), (47, 55)], fill=(40, 50, 90), width=2)
# Scarf trailing back.
d.line([(40, 43), (35, 45), (32, 44)], fill=GOLD, width=1)

OUT.mkdir(exist_ok=True)
for size in (180, 192, 512):
    path = OUT / f"icon-{size}.png"
    img.resize((size, size), Image.NEAREST).save(path)
    print("wrote", path.relative_to(OUT.parent))
