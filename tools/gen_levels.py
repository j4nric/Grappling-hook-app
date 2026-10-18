#!/usr/bin/env python3
"""Generates scenes/levels/level_*.tscn from the compact descriptions below.

The levels are the source of truth here: change a description and run
    python3 tools/gen_levels.py
Do not edit the generated .tscn files by hand (changes would be overwritten).

Coordinates: forward is -Z, the player starts at z=0. The tunnel is 12 m wide
(x -6..6), the floor top is at y=-5, the ceiling bottom at y=9.
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "scenes" / "levels"

FLOOR_Y = -5.0
CEIL_Y = 9.0
HALF_W = 6.0
LAVA_Y = -9.0
# Geometry is cut into pieces of at most this length (m): alternating tones
# show speed, and each piece only gets the few lights near it.
CHUNK = 16.0
TORCH_SPACING = 24.0

# Textured materials from the library (tools/gen_textures.py): name -> file
# in assets/materials/. World-space triplanar, so every chunk tiles on.
LIBRARY = {
    "rock": "rock", "rock2": "rock_dark", "floor": "rock_floor", "floor2": "rock_floor",
    "obstacle": "obstacle", "ice": "ice", "lava": "lava", "mover": "metal",
}
# Plain glowing materials: name -> (albedo rgb, emission rgb)
MATERIALS = {
    "torch": ((1.0, 0.7, 0.3), (1.0, 0.55, 0.2)),
    "finish": ((0.2, 0.85, 0.4), (0.2, 0.85, 0.4)),
    "checkpoint": ((1.0, 0.85, 0.2), (0.6, 0.5, 0.1)),
}


# Medal times (gold, silver, bronze) are set from the test bot's time
# (tests/test_levels.gd prints it): about 85 %, 115 % and 160 % of it.
def level(name, length, medals, floor=None, ceiling_ice=(), left_ice=(), right_ice=(),
          blocks=(), movers=(), checkpoints=(), slabs=()):
    """floor: list of (z_from, z_to) solid floor spans (z_from > z_to); gaps get lava.
    *_ice: list of (z_from, z_to) spans where ceiling/wall does not hold the hook.
    blocks: (x, y, z, sx, sy, sz, ice?) static obstacles.
    movers: (x, y, z, sx, sy, sz, travel(x,y,z), period, phase).
    checkpoints: z positions; respawn above the floor there.
    slabs: (y, z_from, z_to) horizontal dividers across the tunnel."""
    return dict(name=name, length=length, medals=medals,
                floor=floor or [(10.0, -length - 10.0)], ceiling_ice=ceiling_ice,
                left_ice=left_ice, right_ice=right_ice, blocks=blocks, movers=movers,
                checkpoints=checkpoints, slabs=slabs)


LEVELS = [
    level("First Swing", 200, (6.5, 8.8, 12.2),
          floor=[(10.0, -125.0), (-145.0, -210.0)],
          blocks=[(0, 5, -40, 5, 8, 2, False),
                  (-3, -0.5, -80, 2, 9, 2, False),
                  (3, 6, -115, 6, 6, 3, False),
                  (0, -2, -165, 2, 6, 2, False)]),
    level("Lava Gaps", 240, (7.9, 10.7, 14.8),
          floor=[(10.0, -30.0), (-50.0, -70.0), (-95.0, -110.0), (-140.0, -150.0), (-180.0, -250.0)],
          blocks=[(-3, 6, -60, 6, 6, 3, False), (3, 6, -125, 6, 6, 3, False)],
          checkpoints=[-102.0, -185.0]),
    level("Ice Ceiling", 220, (8.4, 11.3, 15.7),
          floor=[(10.0, -110.0), (-125.0, -230.0)],
          ceiling_ice=[(-35.0, -60.0), (-80.0, -105.0), (-150.0, -175.0)],
          left_ice=[(-80.0, -105.0)], right_ice=[(-150.0, -175.0)],
          blocks=[(0, 5, -140, 3, 3, 3, True)],
          checkpoints=[-130.0]),
    level("Movers", 220, (7.4, 10.0, 14.0),
          blocks=[(-4, -1, -30, 2, 8, 2, False), (4, -1, -110, 2, 8, 2, False)],
          movers=[(-4, 4, -50, 4, 6, 2, (8, 0, 0), 3.0, 0.0),
                  (4, 4, -90, 4, 6, 2, (-8, 0, 0), 2.5, 0.3),
                  (-4, 2, -130, 4, 4, 2, (8, 0, 0), 2.0, 0.6),
                  (0, 6, -170, 12, 4, 3, (0, -8, 0), 3.0, 0.0)],
          checkpoints=[-140.0]),
    level("Shortcut", 320, (9.7, 13.1, 18.2),
          floor=[(10.0, -90.0), (-105.0, -150.0), (-165.0, -330.0)],
          slabs=[(2.0, -60.0, -200.0)],
          blocks=[(-3, -2, -120, 2, 6, 2, False), (3, -2, -180, 2, 6, 2, False),
                  (0, 6, -260, 5, 6, 2, False)],
          checkpoints=[-215.0]),
]


class Scene:
    def __init__(self):
        self.exts = []  # (type, path, id)
        self.subs = []  # (type, id, body)
        self.nodes = []
        self.box_meshes = {}
        self.box_shapes = {}

    def sub(self, kind, sid, body):
        self.subs.append((kind, sid, body))
        return sid

    def ext(self, kind, path, eid):
        if not any(e[2] == eid for e in self.exts):
            self.exts.append((kind, path, eid))
        return f'ExtResource("{eid}")'

    def material(self, name):
        """Reference to a material: from the library, or a plain glowing one."""
        if name in LIBRARY:
            file = LIBRARY[name]
            kind = "ShaderMaterial" if file == "lava" else "StandardMaterial3D"
            return self.ext(kind, f"res://assets/materials/{file}.tres", f"m_{file}")
        sid = f"mat_{name}"
        if not any(s[1] == sid for s in self.subs):
            albedo, emission = MATERIALS[name]
            body = (f"albedo_color = Color({albedo[0]}, {albedo[1]}, {albedo[2]}, 1)\n"
                    f"emission_enabled = true\nemission = Color({emission[0]}, {emission[1]}, {emission[2]}, 1)")
            self.sub("StandardMaterial3D", sid, body)
        return f'SubResource("{sid}")'

    def box_shape(self, sx, sy, sz):
        key = (sx, sy, sz)
        if key not in self.box_shapes:
            sid = f"shape_{len(self.box_shapes)}"
            self.box_shapes[key] = self.sub("BoxShape3D", sid, f"size = Vector3({sx}, {sy}, {sz})")
        return self.box_shapes[key]

    def box_mesh(self, sx, sy, sz, mat):
        key = (sx, sy, sz, mat)
        if key not in self.box_meshes:
            sid = f"mesh_{len(self.box_meshes)}"
            self.box_meshes[key] = self.sub(
                "BoxMesh", sid, f'material = {self.material(mat)}\nsize = Vector3({sx}, {sy}, {sz})')
        return self.box_meshes[key]

    def node(self, name, kind, parent=".", pos=None, props="", groups=None):
        head = f'[node name="{name}" type="{kind}" parent="{parent}"'
        if groups:
            head += " groups=[" + ", ".join(f'"{g}"' for g in groups) + "]"
        head += "]"
        lines = [head]
        if pos is not None:
            lines.append(f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {pos[0]}, {pos[1]}, {pos[2]})")
        if props:
            lines.append(props)
        self.nodes.append("\n".join(lines))

    def csg(self, name, parent, pos, size, mat, ice=False):
        self.node(name, "CSGBox3D", parent, pos,
                  f'use_collision = true\nsize = Vector3({size[0]}, {size[1]}, {size[2]})\n'
                  f'material = {self.material("ice" if ice else mat)}',
                  groups=["no_hook"] if ice else None)

    def area(self, name, parent, pos, size):
        self.node(name, "Area3D", parent, pos)
        self.node("CollisionShape3D", "CollisionShape3D", f"{parent}/{name}" if parent != "." else name,
                  props=f'shape = SubResource("{self.box_shape(*size)}")')


def chunks(a, b):
    """Splits the span a > b into pieces of at most CHUNK; yields (a, b, tone)."""
    z = a
    while z > b + 0.001:
        nxt = max(b, (int(z // CHUNK) - (1 if z % CHUNK == 0 else 0)) * CHUNK)
        if nxt >= z:
            nxt = max(b, z - CHUNK)
        yield z, nxt, int(-((z + nxt) / 2) // CHUNK) % 2
        z = nxt


def spans(total_from, total_to, special):
    """Splits [total_from, total_to] (descending z) into (z_from, z_to, is_special)."""
    cuts = sorted({total_from, total_to, *[z for s in special for z in s]}, reverse=True)
    out = []
    for a, b in zip(cuts, cuts[1:]):
        mid = (a + b) / 2
        out.append((a, b, any(s[0] >= mid >= s[1] for s in special)))
    return out


def build(index, lv):
    sc = Scene()
    length = lv["length"]
    z_back, z_end = 10.0, -length - 10.0
    gold, silver, bronze = lv["medals"]
    sc.node("Level", "Node3D", None,
            props=f'script = ExtResource("1_level")\nlevel_name = "{lv["name"]}"\n'
                  f"gold_time = {gold}\nsilver_time = {silver}\nbronze_time = {bronze}")
    sc.nodes[-1] = sc.nodes[-1].replace(' parent="None"', "")

    sc.node("Start", "Marker3D", ".", (0, FLOOR_Y + 1.4, 0))
    sc.node("Geometry", "Node3D")

    # Floor spans; gaps get lava below.
    sc.node("Floor", "Node3D", "Geometry")
    n = 0
    for a0, b0 in lv["floor"]:
        for a, b, tone in chunks(a0, b0):
            sc.csg(f"Floor{n}", "Geometry/Floor", (0, FLOOR_Y - 0.5, (a + b) / 2), (12, 1, a - b),
                   "floor2" if tone else "floor")
            n += 1

    for side, x, ice in (("Ceiling", None, lv["ceiling_ice"]), ("WallLeft", -HALF_W - 0.5, lv["left_ice"]),
                         ("WallRight", HALF_W + 0.5, lv["right_ice"])):
        sc.node(side, "Node3D", "Geometry")
        n = 0
        for a0, b0, is_ice in spans(z_back, z_end, ice):
            for a, b, tone in chunks(a0, b0):
                if x is None:
                    pos, size = (0, CEIL_Y + 0.5, (a + b) / 2), (12, 1, a - b)
                else:
                    pos, size = (x, (FLOOR_Y + CEIL_Y) / 2, (a + b) / 2), (1, CEIL_Y - FLOOR_Y + 2, a - b)
                sc.csg(f"{side}{n}", f"Geometry/{side}", pos, size, "rock2" if tone else "rock", is_ice)
                n += 1
    sc.csg("WallBack", "Geometry", (0, (FLOOR_Y + CEIL_Y) / 2, z_back + 0.5), (12, CEIL_Y - FLOOR_Y + 2, 1), "rock")
    sc.csg("WallEnd", "Geometry", (0, (FLOOR_Y + CEIL_Y) / 2, z_end - 0.5), (12, CEIL_Y - FLOOR_Y + 2, 1), "rock")

    for i, (y, a, b) in enumerate(lv["slabs"]):
        sc.csg(f"Slab{i}", "Geometry", (0, y, (a + b) / 2), (12, 1, a - b), "rock")

    sc.node("Obstacles", "Node3D", "Geometry")
    for i, (x, y, z, sx, sy, sz, ice) in enumerate(lv["blocks"]):
        sc.csg(f"Block{i}", "Geometry/Obstacles", (x, y, z), (sx, sy, sz), "obstacle", ice)

    if lv["movers"]:
        sc.node("Movers", "Node3D")
        for i, (x, y, z, sx, sy, sz, travel, period, phase) in enumerate(lv["movers"]):
            sc.node(f"Mover{i}", "AnimatableBody3D", "Movers", (x, y, z),
                    f'script = ExtResource("2_mover")\ntravel = Vector3({travel[0]}, {travel[1]}, {travel[2]})\n'
                    f"period = {period}\nphase = {phase}")
            sc.node("CollisionShape3D", "CollisionShape3D", f"Movers/Mover{i}",
                    props=f'shape = SubResource("{sc.box_shape(sx, sy, sz)}")')
            sc.node("MeshInstance3D", "MeshInstance3D", f"Movers/Mover{i}",
                    props=f'mesh = SubResource("{sc.box_mesh(sx, sy, sz, "mover")}")')

    # Lava under every floor gap.
    gaps = []
    floor = sorted(lv["floor"], reverse=True)
    for (a1, b1), (a2, b2) in zip(floor, floor[1:]):
        if b1 > a2:
            gaps.append((b1, a2))
    # Torches along the walls, alternating sides.
    sc.node("Lights", "Node3D")
    z, i = 6.0, 0
    while z > -length:
        x = -HALF_W if i % 2 == 0 else HALF_W
        sc.node(f"Torch{i}", "OmniLight3D", "Lights", (x * 0.85, 5.0, z),
                "light_color = Color(1, 0.62, 0.3, 1)\nlight_energy = 2.5\nomni_range = 16.0\n"
                + f'script = {sc.ext("Script", "res://scripts/flicker.gd", "3_flicker")}')
        sc.node(f"TorchMesh{i}", "MeshInstance3D", "Lights", (x * 0.97, 4.5, z),
                f'mesh = SubResource("{sc.box_mesh(0.3, 0.6, 0.3, "torch")}")')
        z -= TORCH_SPACING if i > 0 else 6.0 + TORCH_SPACING / 2
        i += 1

    sc.node("KillZones", "Node3D")
    for i, (a, b) in enumerate(gaps):
        sc.node(f"LavaMesh{i}", "MeshInstance3D", "Geometry", (0, LAVA_Y, (a + b) / 2),
                f'mesh = SubResource("{sc.box_mesh(12, 0.5, a - b, "lava")}")')
        sc.node(f"LavaLight{i}", "OmniLight3D", "Lights", (0, LAVA_Y + 4, (a + b) / 2),
                "light_color = Color(1, 0.35, 0.1, 1)\nlight_energy = 2.5\nomni_range = 14.0\n"
                + f'script = {sc.ext("Script", "res://scripts/flicker.gd", "3_flicker")}\namount = 0.15\nspeed = 3.0')
        sc.area(f"Lava{i}", "KillZones", (0, LAVA_Y + 1.5, (a + b) / 2), (12, 3, a - b))

    sc.node("Checkpoints", "Node3D")
    for i, z in enumerate(lv["checkpoints"]):
        sc.area(f"Checkpoint{i}", "Checkpoints", (0, (FLOOR_Y + CEIL_Y) / 2, z), (12, CEIL_Y - FLOOR_Y, 2))
        sc.node("Respawn", "Marker3D", f"Checkpoints/Checkpoint{i}", (0, FLOOR_Y + 1.4 - (FLOOR_Y + CEIL_Y) / 2, 0))
        sc.node("Marker", "MeshInstance3D", f"Checkpoints/Checkpoint{i}",
                props=f'mesh = SubResource("{sc.box_mesh(12, 0.15, 0.15, "checkpoint")}")\n'
                      f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, {CEIL_Y - (FLOOR_Y + CEIL_Y) / 2 - 0.3}, 0)")

    sc.node("FinishMarker", "CSGBox3D", ".", (0, (FLOOR_Y + CEIL_Y) / 2, -length),
            f'size = Vector3(11.5, {CEIL_Y - FLOOR_Y - 0.5}, 0.3)\nmaterial = {sc.material("finish")}')
    sc.area("Finish", ".", (0, (FLOOR_Y + CEIL_Y) / 2, -length), (12, CEIL_Y - FLOOR_Y, 2))

    ext = ('[ext_resource type="Script" path="res://scripts/level.gd" id="1_level"]\n'
           '[ext_resource type="Script" path="res://scripts/mover.gd" id="2_mover"]\n')
    ext += "".join(f'[ext_resource type="{k}" path="{p}" id="{i}"]\n' for k, p, i in sc.exts)
    head = f"[gd_scene load_steps={len(sc.subs) + len(sc.exts) + 3} format=3]\n\n"
    subs = "\n".join(f'[sub_resource type="{k}" id="{i}"]\n{b}\n' for k, i, b in sc.subs)
    text = head + "; Generated by tools/gen_levels.py - edit the description there.\n\n" + ext + "\n" + subs + "\n" + "\n\n".join(sc.nodes) + "\n"
    path = OUT / f"level_{index + 1:02d}.tscn"
    path.write_text(text)
    print("wrote", path.relative_to(ROOT))


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    for i, lv in enumerate(LEVELS):
        build(i, lv)
