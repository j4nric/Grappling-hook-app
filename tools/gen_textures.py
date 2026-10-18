#!/usr/bin/env python3
"""Paints the game's textures and writes the material library.

    python3 tools/gen_textures.py

Writes assets/textures/*.png (seamless, small: the world is drawn in coarse
pixels anyway) and assets/materials/*.tres (world-space triplanar materials,
so boxes of any size and position tile seamlessly). Fixed seeds: running it
again gives the same files. Needs numpy and Pillow.
"""
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
TEX = ROOT / "assets" / "textures"
MAT = ROOT / "assets" / "materials"
SIZE = 128


# --- Seamless noise ----------------------------------------------------------

def value_noise(size, cells, rng):
    """Smooth periodic noise in 0..1: a random grid of cells x cells,
    interpolated with wrap-around, so the texture tiles."""
    grid = rng.random((cells, cells))
    x = np.arange(size) * cells / size
    i0 = np.floor(x).astype(int)
    f = x - i0
    f = f * f * (3 - 2 * f)
    i1 = (i0 + 1) % cells
    # Rows first, then columns.
    rows = grid[i0] * (1 - f)[:, None] + grid[i1] * f[:, None]
    out = rows[:, i0] * (1 - f)[None, :] + rows[:, i1] * f[None, :]
    return out


def fbm(size, base_cells, octaves, rng, gain=0.5):
    total = np.zeros((size, size))
    amp, norm = 1.0, 0.0
    cells = base_cells
    for _ in range(octaves):
        total += value_noise(size, cells, rng) * amp
        norm += amp
        amp *= gain
        cells *= 2
    return total / norm


def voronoi(size, count, rng):
    """Periodic Voronoi: (F1, F2, cell id) per pixel, distances in pixels."""
    pts = rng.random((count, 2)) * size
    yy, xx = np.mgrid[0:size, 0:size].astype(float)
    best = np.full((size, size), np.inf)
    second = np.full((size, size), np.inf)
    cell = np.zeros((size, size), dtype=int)
    for k, (px, py) in enumerate(pts):
        dx = np.abs(xx - px)
        dy = np.abs(yy - py)
        dx = np.minimum(dx, size - dx)
        dy = np.minimum(dy, size - dy)
        d = np.sqrt(dx * dx + dy * dy)
        closer = d < best
        second = np.where(closer, best, np.minimum(second, d))
        cell = np.where(closer, k, cell)
        best = np.where(closer, d, best)
    return best, second, cell


def normal_map(height, strength):
    """Tangent-space normal map from a height field (wrap-around slopes)."""
    dx = (np.roll(height, -1, axis=1) - np.roll(height, 1, axis=1)) * strength
    dy = (np.roll(height, -1, axis=0) - np.roll(height, 1, axis=0)) * strength
    n = np.stack([-dx, dy, np.ones_like(height)], axis=-1)
    n /= np.linalg.norm(n, axis=-1, keepdims=True)
    return n * 0.5 + 0.5


def ramp(t, stops):
    """Color ramp: stops = [(t, (r, g, b)), ...] ascending."""
    t = np.clip(t, 0, 1)
    out = np.zeros(t.shape + (3,))
    ts = [s[0] for s in stops]
    for c in range(3):
        out[..., c] = np.interp(t, ts, [s[1][c] for s in stops])
    return out


def save(name, rgb, alpha=None):
    arr = np.clip(rgb, 0, 1)
    if arr.ndim == 2:
        arr = np.stack([arr] * 3, axis=-1)
    if alpha is not None:
        arr = np.concatenate([arr, np.clip(alpha, 0, 1)[..., None]], axis=-1)
    img = Image.fromarray((arr * 255 + 0.5).astype(np.uint8))
    path = TEX / f"{name}.png"
    img.save(path)
    print("wrote", path.relative_to(ROOT), img.size)
    write_import(path, mipmaps=alpha is None)


def write_import(path, mipmaps):
    """Lossless, mipmapped import settings. Godot fills in the rest on import.
    No VRAM compression: iPhone browsers lack the desktop formats."""
    imp = path.with_suffix(".png.import")
    if imp.exists():
        text = imp.read_text()
        text = text.replace("mipmaps/generate=false", f"mipmaps/generate={str(mipmaps).lower()}")
        text = text.replace("mipmaps/generate=true", f"mipmaps/generate={str(mipmaps).lower()}")
        text = text.replace("detect_3d/compress_to=1", "detect_3d/compress_to=0")
        imp.write_text(text)
        return
    imp.write_text(
        '[remap]\n\nimporter="texture"\ntype="CompressedTexture2D"\n\n[params]\n\n'
        "compress/mode=0\n"
        f"mipmaps/generate={str(mipmaps).lower()}\n"
        "detect_3d/compress_to=0\n")


# --- Textures ----------------------------------------------------------------

def rock():
    rng = np.random.default_rng(11)
    base = fbm(SIZE, 4, 6, rng)
    # Sediment layers, bent by noise.
    warp = fbm(SIZE, 2, 3, rng)
    yy = np.mgrid[0:SIZE, 0:SIZE][0] / SIZE
    strata = 0.5 + 0.5 * np.sin((yy * 5 + warp * 2.0) * 2 * np.pi)
    # Cracks: thin Voronoi borders, but only where a noise mask lets them
    # through, so they break off instead of tiling the rock like paving.
    f1, f2, cell = voronoi(SIZE, 26, rng)
    line = 1 - np.clip((f2 - f1) / 1.4, 0, 1)
    mask = np.clip((fbm(SIZE, 4, 3, rng) - 0.42) * 6, 0, 1)
    crack = line * mask
    lumps = fbm(SIZE, 8, 3, rng)
    height = base * 0.6 + strata * 0.15 + lumps * 0.25 - crack * 0.35
    speck = (rng.random((SIZE, SIZE)) > 0.975) * 0.08
    tone = height + speck
    albedo = ramp(tone, [(0.0, (0.08, 0.07, 0.07)), (0.3, (0.27, 0.25, 0.24)),
                         (0.55, (0.45, 0.42, 0.39)), (0.8, (0.63, 0.59, 0.54)),
                         (1.0, (0.78, 0.74, 0.68))])
    # A touch of rust and moss in hollows.
    stain = fbm(SIZE, 4, 3, rng)
    albedo[..., 0] *= 1 + (stain - 0.5) * 0.25
    albedo[..., 2] *= 1 - (stain - 0.5) * 0.2
    save("rock_albedo", albedo)
    save("rock_normal", normal_map(height, 4.0))


def metal():
    rng = np.random.default_rng(23)
    yy, xx = np.mgrid[0:SIZE, 0:SIZE]
    plate = 32
    px, py = xx % plate, yy % plate
    seams = ((px < 2) | (py < 2)).astype(float)
    rivet = (((px - 6) ** 2 + (py - 6) ** 2) < 5).astype(float)
    rust = fbm(SIZE, 4, 4, rng)
    rust_mask = np.clip((rust - 0.5) * 4, 0, 1)
    scratches = fbm(SIZE, 16, 2, rng) * 0.15
    height = 0.6 - seams * 0.5 + rivet * 0.4 + scratches
    base = ramp(0.45 + scratches + rivet * 0.3 - seams * 0.3,
                [(0.0, (0.12, 0.12, 0.13)), (0.5, (0.42, 0.43, 0.45)), (1.0, (0.75, 0.76, 0.78))])
    rust_col = ramp(rust, [(0.0, (0.35, 0.15, 0.06)), (1.0, (0.62, 0.32, 0.12))])
    albedo = base * (1 - rust_mask[..., None] * 0.8) + rust_col * rust_mask[..., None] * 0.8
    save("metal_albedo", albedo)
    save("metal_normal", normal_map(height, 2.0))


def ice():
    rng = np.random.default_rng(31)
    f1, f2, cell = voronoi(SIZE, 14, rng)
    edge = 1 - np.clip((f2 - f1) / 2.5, 0, 1)
    frost = fbm(SIZE, 8, 4, rng)
    xx = np.mgrid[0:SIZE, 0:SIZE][1] / SIZE
    streak = 0.5 + 0.5 * np.sin((xx * 3 + frost) * 2 * np.pi)
    tone = 0.45 + rng.random(14)[cell] * 0.2 + frost * 0.2 + streak * 0.1
    albedo = ramp(tone, [(0.0, (0.25, 0.45, 0.6)), (0.6, (0.6, 0.82, 0.95)), (1.0, (0.92, 0.98, 1.0))])
    albedo = albedo * (1 - edge[..., None] * 0.15) + edge[..., None] * 0.15
    save("ice_albedo", albedo)
    save("ice_emission", ramp(edge * 0.8 + frost * 0.2, [(0.0, (0.0, 0.0, 0.0)), (1.0, (0.45, 0.8, 1.0))]))
    save("ice_normal", normal_map(tone - edge * 0.3, 2.5))


def crystal():
    rng = np.random.default_rng(41)
    f1, f2, cell = voronoi(SIZE, 10, rng)
    facet = rng.random(10)[cell]
    edge = 1 - np.clip((f2 - f1) / 2.0, 0, 1)
    tone = facet * 0.7 + edge * 0.3
    save("crystal_albedo", ramp(tone, [(0.0, (0.15, 0.3, 0.45)), (1.0, (0.7, 0.95, 1.0))]))
    save("crystal_emission", ramp(tone, [(0.0, (0.02, 0.1, 0.2)), (0.7, (0.2, 0.6, 0.9)), (1.0, (0.8, 1.0, 1.0))]))


def lava_noise():
    rng = np.random.default_rng(53)
    save("lava_noise", fbm(SIZE, 4, 5, rng, gain=0.6))


def dust():
    """Soft round mote with a bright core (billboard particle)."""
    n = 16
    yy, xx = np.mgrid[0:n, 0:n] + 0.5
    r = np.sqrt((xx - n / 2) ** 2 + (yy - n / 2) ** 2) / (n / 2)
    alpha = np.clip(1 - r, 0, 1) ** 2
    save("dust", np.ones((n, n)), alpha)


def light_shaft():
    """Vertical beam: bright at the top, fading down, soft edges, faint streaks."""
    rng = np.random.default_rng(61)
    w, h = 64, 256
    yy, xx = np.mgrid[0:h, 0:w]
    across = np.abs(xx / (w - 1) * 2 - 1)
    edge = np.clip(1 - across, 0, 1) ** 1.5
    fade = (1 - yy / (h - 1)) ** 1.3
    streak = 0.75 + 0.25 * value_noise(w, 8, rng)[0][xx]
    alpha = edge * fade * streak
    save("light_shaft", np.ones((h, w)), alpha)


def vignette():
    """Screen overlay: transparent center, dark corners (portrait ratio)."""
    w, h = 128, 256
    yy, xx = np.mgrid[0:h, 0:w]
    dx = (xx + 0.5) / w * 2 - 1
    dy = ((yy + 0.5) / h * 2 - 1)
    r = np.sqrt(dx * dx * 0.8 + dy * dy * 0.9)
    alpha = np.clip((r - 0.55) / 0.75, 0, 1) ** 1.6 * 0.85
    save("vignette", np.zeros((h, w)), alpha)


# --- Materials ---------------------------------------------------------------

# name -> settings. scale: texture repeats per meter (triplanar, world space).
MATERIALS = {
    "rock": dict(albedo="rock_albedo", normal="rock_normal", tint=(0.85, 0.8, 0.75), scale=0.18),
    "rock_dark": dict(albedo="rock_albedo", normal="rock_normal", tint=(0.5, 0.5, 0.56), scale=0.18),
    "rock_floor": dict(albedo="rock_albedo", normal="rock_normal", tint=(0.72, 0.66, 0.6), scale=0.3),
    "obstacle": dict(albedo="rock_albedo", normal="rock_normal", tint=(0.95, 0.62, 0.5), scale=0.35),
    "metal": dict(albedo="metal_albedo", normal="metal_normal", tint=(1.0, 0.9, 0.8), scale=0.25,
                  metallic=0.6, roughness=0.5),
    "ice": dict(albedo="ice_albedo", normal="ice_normal", emission="ice_emission", tint=(1, 1, 1),
                scale=0.2, roughness=0.25, emission_energy=0.8),
    "crystal": dict(albedo="crystal_albedo", emission="crystal_emission", tint=(1, 1, 1), scale=0.5,
                    roughness=0.2, emission_energy=2.5),
}


def write_material(name, m):
    ext = []
    props = [f"albedo_color = Color({m['tint'][0]}, {m['tint'][1]}, {m['tint'][2]}, 1)"]

    def tex(key):
        ext.append(f'[ext_resource type="Texture2D" path="res://assets/textures/{m[key]}.png" id="{len(ext) + 1}"]')
        return f'ExtResource("{len(ext)}")'

    props.append(f"albedo_texture = {tex('albedo')}")
    props.append(f"metallic = {m.get('metallic', 0.0)}")
    props.append(f"roughness = {m.get('roughness', 0.9)}")
    if "emission" in m:
        props += ["emission_enabled = true", "emission = Color(1, 1, 1, 1)",
                  f"emission_energy_multiplier = {m.get('emission_energy', 1.0)}",
                  f"emission_texture = {tex('emission')}"]
    if "normal" in m:
        props += ["normal_enabled = true", f"normal_texture = {tex('normal')}"]
    s = m["scale"]
    props += [f"uv1_scale = Vector3({s}, {s}, {s})", "uv1_triplanar = true", "uv1_world_triplanar = true",
              "texture_filter = 2"]
    text = (f"[gd_resource type=\"StandardMaterial3D\" load_steps={len(ext) + 1} format=3]\n\n"
            + "\n".join(ext) + "\n\n[resource]\n" + "\n".join(props) + "\n")
    path = MAT / f"{name}.tres"
    path.write_text(text)
    print("wrote", path.relative_to(ROOT))


def write_lava():
    text = ('[gd_resource type="ShaderMaterial" load_steps=3 format=3]\n\n'
            '[ext_resource type="Shader" path="res://shaders/lava.gdshader" id="1"]\n'
            '[ext_resource type="Texture2D" path="res://assets/textures/lava_noise.png" id="2"]\n\n'
            '[resource]\nrender_priority = 0\nshader = ExtResource("1")\n'
            'shader_parameter/noise = ExtResource("2")\n')
    path = MAT / "lava.tres"
    path.write_text(text)
    print("wrote", path.relative_to(ROOT))


def main():
    TEX.mkdir(parents=True, exist_ok=True)
    MAT.mkdir(parents=True, exist_ok=True)
    rock()
    metal()
    ice()
    crystal()
    lava_noise()
    dust()
    light_shaft()
    vignette()
    for name, m in MATERIALS.items():
        write_material(name, m)
    write_lava()


if __name__ == "__main__":
    main()
