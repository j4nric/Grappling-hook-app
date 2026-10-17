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

# Materials: name -> (albedo rgb, emission rgb or None)
MATERIALS = {
    "rock": ((0.36, 0.34, 0.31), None),
    "floor": ((0.24, 0.23, 0.21), None),
    "obstacle": ((0.52, 0.31, 0.25), None),
    "ice": ((0.55, 0.8, 0.95), (0.1, 0.25, 0.35)),
    "lava": ((1.0, 0.35, 0.05), (1.0, 0.3, 0.0)),
    "finish": ((0.2, 0.85, 0.4), (0.2, 0.85, 0.4)),
    "checkpoint": ((1.0, 0.85, 0.2), (0.6, 0.5, 0.1)),
    "mover": ((0.75, 0.45, 0.2), None),
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
    level("First Swing", 200, (11.5, 15.5, 22.0),
          floor=[(10.0, -125.0), (-145.0, -210.0)],
          blocks=[(0, 5, -40, 5, 8, 2, False),
                  (-3, -0.5, -80, 2, 9, 2, False),
                  (3, 6, -115, 6, 6, 3, False),
                  (0, -2, -165, 2, 6, 2, False)]),
    level("Lava Gaps", 240, (11.5, 16.0, 22.0),
          floor=[(10.0, -30.0), (-50.0, -70.0), (-95.0, -110.0), (-140.0, -150.0), (-180.0, -250.0)],
          blocks=[(-3, 6, -60, 6, 6, 3, False), (3, 6, -125, 6, 6, 3, False)],
          checkpoints=[-102.0, -185.0]),
    level("Ice Ceiling", 220, (17.0, 23.0, 32.0),
          floor=[(10.0, -110.0), (-125.0, -230.0)],
          ceiling_ice=[(-35.0, -60.0), (-80.0, -105.0), (-150.0, -175.0)],
          left_ice=[(-80.0, -105.0)], right_ice=[(-150.0, -175.0)],
          blocks=[(0, 5, -140, 3, 3, 3, True)],
          checkpoints=[-130.0]),
    level("Movers", 220, (10.0, 14.0, 19.0),
          blocks=[(-4, -1, -30, 2, 8, 2, False), (4, -1, -110, 2, 8, 2, False)],
          movers=[(-4, 4, -50, 4, 6, 2, (8, 0, 0), 3.0, 0.0),
                  (4, 4, -90, 4, 6, 2, (-8, 0, 0), 2.5, 0.3),
                  (-4, 2, -130, 4, 4, 2, (8, 0, 0), 2.0, 0.6),
                  (0, 6, -170, 12, 4, 3, (0, -8, 0), 3.0, 0.0)],
          checkpoints=[-140.0]),
    level("Shortcut", 320, (14.5, 20.0, 28.0),
          floor=[(10.0, -90.0), (-105.0, -150.0), (-165.0, -330.0)],
          slabs=[(2.0, -60.0, -200.0)],
          blocks=[(-3, -2, -120, 2, 6, 2, False), (3, -2, -180, 2, 6, 2, False),
                  (0, 6, -260, 5, 6, 2, False)],
          checkpoints=[-215.0]),
]


class Scene:
    def __init__(self):
        self.subs = []  # (type, id, body)
        self.nodes = []
        self.box_meshes = {}
        self.box_shapes = {}

    def sub(self, kind, sid, body):
        self.subs.append((kind, sid, body))
        return sid

    def material(self, name):
        sid = f"mat_{name}"
        if not any(s[1] == sid for s in self.subs):
            albedo, emission = MATERIALS[name]
            body = f"albedo_color = Color({albedo[0]}, {albedo[1]}, {albedo[2]}, 1)"
            if emission:
                body += f"\nemission_enabled = true\nemission = Color({emission[0]}, {emission[1]}, {emission[2]}, 1)"
            self.sub("StandardMaterial3D", sid, body)
        return sid

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
                "BoxMesh", sid, f'material = SubResource("{self.material(mat)}")\nsize = Vector3({sx}, {sy}, {sz})')
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
                  f'material = SubResource("{self.material("ice" if ice else mat)}")',
                  groups=["no_hook"] if ice else None)

    def area(self, name, parent, pos, size):
        self.node(name, "Area3D", parent, pos)
        self.node("CollisionShape3D", "CollisionShape3D", f"{parent}/{name}" if parent != "." else name,
                  props=f'shape = SubResource("{self.box_shape(*size)}")')


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
    for i, (a, b) in enumerate(lv["floor"]):
        sc.csg(f"Floor{i}", "Geometry/Floor", (0, FLOOR_Y - 0.5, (a + b) / 2), (12, 1, a - b), "floor")

    for side, x, ice in (("Ceiling", None, lv["ceiling_ice"]), ("WallLeft", -HALF_W - 0.5, lv["left_ice"]),
                         ("WallRight", HALF_W + 0.5, lv["right_ice"])):
        sc.node(side, "Node3D", "Geometry")
        for i, (a, b, is_ice) in enumerate(spans(z_back, z_end, ice)):
            if x is None:
                pos, size = (0, CEIL_Y + 0.5, (a + b) / 2), (12, 1, a - b)
            else:
                pos, size = (x, (FLOOR_Y + CEIL_Y) / 2, (a + b) / 2), (1, CEIL_Y - FLOOR_Y + 2, a - b)
            sc.csg(f"{side}{i}", f"Geometry/{side}", pos, size, "rock", is_ice)
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
    sc.node("KillZones", "Node3D")
    for i, (a, b) in enumerate(gaps):
        sc.node(f"LavaMesh{i}", "MeshInstance3D", "Geometry", (0, LAVA_Y, (a + b) / 2),
                f'mesh = SubResource("{sc.box_mesh(12, 0.5, a - b, "lava")}")')
        sc.area(f"Lava{i}", "KillZones", (0, LAVA_Y + 1.5, (a + b) / 2), (12, 3, a - b))

    sc.node("Checkpoints", "Node3D")
    for i, z in enumerate(lv["checkpoints"]):
        sc.area(f"Checkpoint{i}", "Checkpoints", (0, (FLOOR_Y + CEIL_Y) / 2, z), (12, CEIL_Y - FLOOR_Y, 2))
        sc.node("Respawn", "Marker3D", f"Checkpoints/Checkpoint{i}", (0, FLOOR_Y + 1.4 - (FLOOR_Y + CEIL_Y) / 2, 0))
        sc.node("Marker", "MeshInstance3D", f"Checkpoints/Checkpoint{i}",
                props=f'mesh = SubResource("{sc.box_mesh(12, 0.15, 0.15, "checkpoint")}")\n'
                      f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, {CEIL_Y - (FLOOR_Y + CEIL_Y) / 2 - 0.3}, 0)")

    sc.node("FinishMarker", "CSGBox3D", ".", (0, (FLOOR_Y + CEIL_Y) / 2, -length),
            f'size = Vector3(11.5, {CEIL_Y - FLOOR_Y - 0.5}, 0.3)\nmaterial = SubResource("{sc.material("finish")}")')
    sc.area("Finish", ".", (0, (FLOOR_Y + CEIL_Y) / 2, -length), (12, CEIL_Y - FLOOR_Y, 2))

    ext = ('[ext_resource type="Script" path="res://scripts/level.gd" id="1_level"]\n'
           '[ext_resource type="Script" path="res://scripts/mover.gd" id="2_mover"]\n')
    head = f"[gd_scene load_steps={len(sc.subs) + 3} format=3]\n\n"
    subs = "\n".join(f'[sub_resource type="{k}" id="{i}"]\n{b}\n' for k, i, b in sc.subs)
    text = head + "; Generated by tools/gen_levels.py - edit the description there.\n\n" + ext + "\n" + subs + "\n" + "\n\n".join(sc.nodes) + "\n"
    path = OUT / f"level_{index + 1:02d}.tscn"
    path.write_text(text)
    print("wrote", path.relative_to(ROOT))


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    for i, lv in enumerate(LEVELS):
        build(i, lv)
