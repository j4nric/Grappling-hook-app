#!/usr/bin/env python3
"""Draws the boot splash (assets/splash.png) shown while the game loads.

    python3 tools/gen_splash.py
"""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

OUT = Path(__file__).resolve().parent.parent / "assets" / "splash.png"
W, H = 360, 360  # drawn small, scaled up with nearest filter for the pixel look
BG = (10, 9, 13)
GOLD = (232, 197, 71)
ROCK = (66, 58, 52)
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"

img = Image.new("RGB", (W, H), BG)
d = ImageDraw.Draw(img)
# Cave arch.
d.rectangle([60, 40, 300, 56], fill=ROCK)
d.rectangle([60, 40, 76, 230], fill=ROCK)
d.rectangle([284, 40, 300, 230], fill=ROCK)
# Hook in the ceiling, rope and a swinging figure.
d.polygon([(172, 56), (188, 56), (180, 72)], fill=(210, 210, 220))
d.line([(180, 70), (230, 170)], fill=GOLD, width=3)
d.ellipse([222, 160, 242, 180], fill=(237, 189, 148))
d.rounded_rectangle([220, 178, 244, 214], radius=8, fill=(184, 56, 41))
font = ImageFont.truetype(FONT, 30)
for text, y in (("GRAPPLING", 250), ("CAVE", 288)):
    box = d.textbbox((0, 0), text, font=font)
    d.text(((W - (box[2] - box[0])) // 2, y), text, font=font, fill=GOLD)
img = img.resize((W * 2, H * 2), Image.NEAREST)
img.save(OUT)
print("wrote", OUT)
