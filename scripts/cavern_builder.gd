class_name CavernBuilder
extends RefCounted
## Builds a cave level from a layout: wide halls one after another along -Z,
## over an abyss. Each hall (a "segment" dictionary, keys in SEGMENT_DEFAULTS)
## gets irregular walls and ceiling from rotated rock blocks plus the hook
## targets: stalactites, pillars rising from the depth, floating rock islands,
## wall outcrops, glowing crystals and light shafts.
## The same seed gives the same cave. Used by the authored levels (layout in
## their .tscn) and by the procedural level (layout from a seed).
##
## Output, as children of the level (see level.gd): Start, Geometry, Props,
## Lights, Movers, KillZones, Checkpoints, Finish, FinishMarker.

const MATERIALS := {
	"rock": preload("res://assets/materials/rock.tres"),
	"rock_dark": preload("res://assets/materials/rock_dark.tres"),
	"rock_floor": preload("res://assets/materials/rock_floor.tres"),
	"obstacle": preload("res://assets/materials/obstacle.tres"),
	"ice": preload("res://assets/materials/ice.tres"),
	"metal": preload("res://assets/materials/metal.tres"),
	"lava": preload("res://assets/materials/lava.tres"),
}
const CRYSTAL := preload("res://scenes/props/crystal.tscn")
const SHAFT := preload("res://scenes/props/light_shaft.tscn")
const MOVER := preload("res://scripts/mover.gd")
const FLICKER := preload("res://scripts/flicker.gd")
const NO_HOOK_GROUP := "no_hook"

## Top of the ledges (start, checkpoints, finish).
const LEDGE_Y := 0.0
## Walls and pillars reach down to here; below is only fog.
const DEPTH_Y := -60.0
## Lava lakes lie this deep.
const LAVA_Y := -24.0

const SEGMENT_DEFAULTS := {
	"length": 60.0,
	"width": 40.0,
	## Ceiling height above the ledges.
	"ceiling": 26.0,
	## "abyss" (nothing below), "ground" (rock floor at ledge height) or "lava".
	"floor": "abyss",
	## Stalactites per 10 m.
	"stalactites": 0.6,
	"pillars": 0,
	"islands": 0,
	## Outcrops on the walls per 10 m (hook targets at the sides).
	"outcrops": 0.3,
	"crystals": 2,
	"shafts": 1,
	## Share of ceiling blocks that are ice (do not hold the hook).
	"ice": 0.0,
	## Ice on stalactites too.
	"ice_stalactites": false,
	## Guaranteed rock stalactites near the middle every this many meters
	## (0 = none, -1 = automatic: in mostly icy halls), so a hall never runs
	## out of hook targets.
	"anchor_spacing": -1.0,
	## A ledge with a checkpoint at the start of the hall.
	"checkpoint": false,
	## Ice wall across the hall with a slit: [x, width] of the opening. It
	## reaches from the depth to just under the ceiling, with a rock island
	## behind it as the target to swing through to.
	"gate": [],
	## Moving blocks: [x, y, z_from_hall_start, sx, sy, sz, travel(Vector3), period, phase].
	"movers": [],
	## Fixed blocks: [x, y, z_from_hall_start, sx, sy, sz, "rock"|"ice"|"obstacle"].
	"blocks": [],
}

var _level: Node3D
var _rng := RandomNumberGenerator.new()
## Per hall: material name -> Array of [Transform3D (scaled unit box)].
var _meshes := {}
var _body: StaticBody3D
var _ice_body: StaticBody3D
var _hall := 0


## Builds the whole cave into level. Returns the z of the finish line.
func build(level: Node3D, segments: Array, seed_value: int) -> float:
	_level = level
	_rng.seed = seed_value
	for group in ["Geometry", "Props", "Lights", "Movers", "KillZones", "Checkpoints"]:
		_add(Node3D.new(), group)

	var start := Marker3D.new()
	start.position = Vector3(0, LEDGE_Y + 1.0, 0)
	_add(start, "Start")

	var z := 0.0
	var first: Dictionary = _segment(segments[0] if not segments.is_empty() else {})
	_begin_hall()
	# Back of the cave behind the start, and the start ledge.
	_box("rock_dark", Vector3(0, (DEPTH_Y + first.ceiling) / 2.0, 14.0),
			Vector3(first.width + 20.0, first.ceiling - DEPTH_Y + 20.0, 6.0), Vector3.ZERO)
	_ledge(Vector3(0, LEDGE_Y, 3.0), Vector3(12.0, 4.0, 18.0))
	_warm_light(Vector3(0, LEDGE_Y + 5.0, 2.0))
	_walls(first, 12.0, 0.0)
	_ceiling(first, 12.0, 0.0)
	_end_hall()

	var prev := first
	for raw in segments:
		var seg := _segment(raw)
		_begin_hall()
		_transition(prev, seg, z)
		_build_hall(seg, z)
		_end_hall()
		z -= float(seg.length)
		prev = seg

	var last: Dictionary = _segment(segments[-1] if not segments.is_empty() else {})
	_begin_hall()
	_finish(last, z)
	_end_hall()
	return z


func _segment(raw: Dictionary) -> Dictionary:
	var seg := SEGMENT_DEFAULTS.duplicate(true)
	seg.merge(raw, true)
	return seg


# --- Halls -----------------------------------------------------------------------

func _build_hall(seg: Dictionary, z0: float) -> void:
	var length: float = seg.length
	var z1 := z0 - length
	_walls(seg, z0, z1)
	_ceiling(seg, z0, z1)
	match seg.floor:
		"ground":
			# Solid down into the depth: nothing to fly under.
			_box("rock_floor", Vector3(0, (LEDGE_Y + DEPTH_Y) / 2.0, (z0 + z1) / 2.0),
					Vector3(seg.width + 6.0, LEDGE_Y - DEPTH_Y, length + 0.5), Vector3.ZERO)
		"lava":
			_lava(seg, z0, z1)
	if seg.checkpoint:
		_checkpoint(seg, z0 - 6.0)

	var w: float = seg.width
	var c: float = seg.ceiling
	for i in roundi(float(seg.stalactites) * length / 10.0):
		_stalactite(Vector3(_rng.randf_range(-w / 2.0 + 5.0, w / 2.0 - 5.0), c, _rng.randf_range(z1 + 3.0, z0 - 3.0)),
				_rng.randf_range(4.0, minf(13.0, c - 6.0)), seg.ice_stalactites)
	var spacing: float = seg.anchor_spacing
	if spacing < 0.0:
		spacing = 18.0 if float(seg.ice) >= 0.5 or seg.ice_stalactites else 0.0
	if spacing > 0.0:
		var az := z0 - spacing / 2.0
		while az > z1:
			_stalactite(Vector3(_rng.randf_range(-8.0, 8.0), c, az), _rng.randf_range(6.0, minf(12.0, c - 8.0)), false)
			az -= spacing
	for i in int(seg.pillars):
		var x := _rng.randf_range(-w / 2.0 + 6.0, w / 2.0 - 6.0)
		_pillar(Vector3(x, 0, z0 - length * (i + 0.5) / float(seg.pillars) + _rng.randf_range(-4.0, 4.0)), c)
	for i in int(seg.islands):
		var pos := Vector3(_rng.randf_range(-w / 2.0 + 7.0, w / 2.0 - 7.0), _rng.randf_range(4.0, c - 9.0),
				z0 - length * (i + 0.5) / float(seg.islands) + _rng.randf_range(-5.0, 5.0))
		_island(pos)
	for i in roundi(float(seg.outcrops) * length / 10.0):
		_outcrop(seg, _rng.randf_range(z1 + 2.0, z0 - 2.0))
	for i in int(seg.crystals):
		_crystal_on_wall(seg, z0 - length * (i + 0.5) / float(seg.crystals))
	for i in int(seg.shafts):
		_shaft(Vector3(_rng.randf_range(-w / 3.0, w / 3.0), c, z0 - length * (i + 0.5) / float(seg.shafts)))
	if not (seg.gate as Array).is_empty():
		_gate(seg, z0 - length / 2.0)
	for b in seg.blocks:
		_box(b[6], Vector3(b[0], b[1], z0 - b[2]), Vector3(b[3], b[4], b[5]), Vector3.ZERO)
	for m in seg.movers:
		_mover(Vector3(m[0], m[1], z0 - m[2]), Vector3(m[3], m[4], m[5]), m[6], m[7], m[8])


## Where the next hall is lower or narrower, a slanted slab leads into it:
## a flat step would stop the player dead, a slope redirects the flight.
func _transition(prev: Dictionary, next: Dictionary, z: float) -> void:
	var drop := float(prev.ceiling) - float(next.ceiling)
	if drop > 0.5:
		var run := maxf(drop * 2.5, 8.0)
		var face := Vector3(0, float(prev.ceiling) - drop / 2.0, z + run / 2.0)
		var along := Vector3(0, drop, run)
		_slab("rock_dark", face, Vector3(0, -run, drop).normalized(), along, float(prev.width) + 10.0, 8.0)
	var narrow := (float(prev.width) - float(next.width)) / 2.0
	if narrow > 0.5:
		var run := maxf(narrow * 2.5, 8.0)
		for side in [-1.0, 1.0]:
			var face := Vector3(side * (float(next.width) / 2.0 + narrow / 2.0), (DEPTH_Y + float(prev.ceiling)) / 2.0, z + run / 2.0)
			var along := Vector3(side * narrow, 0, run)
			var normal := Vector3(-side * run, 0, narrow).normalized()
			_slab("rock", face, normal, along, float(prev.ceiling) - DEPTH_Y + 10.0, 8.0)


## A box whose big face (center `face`, outward `normal`) runs along `along`;
## `across` is its size in the third direction.
func _slab(material: String, face: Vector3, normal: Vector3, along: Vector3, across: float, thick: float) -> void:
	var z_axis := along.normalized()
	var y_axis := -normal
	var x_axis := y_axis.cross(z_axis).normalized()
	z_axis = x_axis.cross(y_axis).normalized()
	_box_basis(material, face - normal * thick / 2.0, Vector3(across, thick, along.length() + 2.0),
			Basis(x_axis, y_axis, z_axis))


## Irregular walls: thick rock slabs, shifted and tilted, down into the depth.
func _walls(seg: Dictionary, z0: float, z1: float) -> void:
	var w: float = seg.width
	var c: float = seg.ceiling
	var z := z0
	var n := 0
	while z > z1 + 0.1:
		var piece := minf(_rng.randf_range(7.0, 13.0), z - z1)
		for side in [-1.0, 1.0]:
			var thick := _rng.randf_range(4.0, 8.0)
			var x: float = side * (w / 2.0 + thick / 2.0 + _rng.randf_range(-1.5, 1.5))
			var top := c + 12.0
			_box("rock" if n % 2 == 0 else "rock_dark", Vector3(x, (DEPTH_Y + top) / 2.0, z - piece / 2.0),
					Vector3(thick, top - DEPTH_Y, piece + 3.0),
					Vector3(_rng.randf_range(-0.05, 0.05), _rng.randf_range(-0.15, 0.15), _rng.randf_range(-0.08, 0.08)))
			n += 1
		z -= piece


## Ceiling from big blocks at slightly different heights: a rough vault.
func _ceiling(seg: Dictionary, z0: float, z1: float) -> void:
	var w: float = seg.width
	var c: float = seg.ceiling
	var columns := maxi(2, ceili(w / 14.0))
	var col_w := (w + 8.0) / columns
	# A solid lid above the blocks: no pockets on top of them to get stuck in.
	_box("rock_dark", Vector3(0, c + 8.0, (z0 + z1) / 2.0), Vector3(w + 16.0, 12.0, z0 - z1 + 2.0), Vector3.ZERO)
	var z := z0
	while z > z1 + 0.1:
		var piece := minf(_rng.randf_range(8.0, 14.0), z - z1)
		for i in columns:
			var x := -w / 2.0 - 4.0 + col_w * (i + 0.5)
			var thick := _rng.randf_range(5.0, 9.0)
			var bottom := c + _rng.randf_range(-2.0, 1.0)
			var ice := _rng.randf() < float(seg.ice)
			_box("ice" if ice else ("rock_dark" if (i + int(z)) % 3 == 0 else "rock"),
					Vector3(x, bottom + thick / 2.0, z - piece / 2.0), Vector3(col_w + 3.0, thick, piece + 3.0),
					Vector3(_rng.randf_range(-0.06, 0.06), _rng.randf_range(-0.2, 0.2), _rng.randf_range(-0.06, 0.06)))
		z -= piece


func _stalactite(top: Vector3, length: float, ice: bool) -> void:
	var thick := _rng.randf_range(1.6, 3.0)
	var tilt := Vector3(_rng.randf_range(-0.08, 0.08), _rng.randf_range(0, TAU), _rng.randf_range(-0.08, 0.08))
	var mat := "ice" if ice else "rock"
	# Upper body and a narrower tip: tapers like a stalactite.
	_box(mat, top + Vector3(0, -length * 0.35 + 1.0, 0), Vector3(thick, length * 0.7, thick), tilt)
	_box(mat, top + Vector3(0, -length * 0.8 + 1.0, 0), Vector3(thick * 0.55, length * 0.4, thick * 0.55), tilt)


## A column rising out of the depth, ending in a broken top below the ceiling
## (or reaching it).
func _pillar(base: Vector3, ceiling: float) -> void:
	var r := _rng.randf_range(1.8, 3.5)
	var top := ceiling + 2.0 if _rng.randf() < 0.5 else _rng.randf_range(4.0, ceiling - 8.0)
	_box("rock", Vector3(base.x, (DEPTH_Y + top) / 2.0, base.z), Vector3(r * 2.0, top - DEPTH_Y, r * 2.0),
			Vector3(0, _rng.randf_range(0, TAU), _rng.randf_range(-0.04, 0.04)))
	_box("rock_dark", Vector3(base.x, top - 0.5, base.z), Vector3(r * 2.6, 2.0, r * 2.6),
			Vector3(_rng.randf_range(-0.2, 0.2), _rng.randf_range(0, TAU), _rng.randf_range(-0.2, 0.2)))


## Floating rock island: a flat-ish top and a jagged underside.
func _island(center: Vector3) -> void:
	var size := Vector3(_rng.randf_range(5.0, 9.0), _rng.randf_range(2.5, 4.0), _rng.randf_range(5.0, 9.0))
	_box("rock", center, size, Vector3(_rng.randf_range(-0.1, 0.1), _rng.randf_range(0, TAU), _rng.randf_range(-0.1, 0.1)))
	for i in 2:
		var s := size * Vector3(_rng.randf_range(0.35, 0.6), _rng.randf_range(0.8, 1.4), _rng.randf_range(0.35, 0.6))
		_box("rock_dark", center + Vector3(_rng.randf_range(-1.5, 1.5), -size.y * 0.6, _rng.randf_range(-1.5, 1.5)), s,
				Vector3(_rng.randf_range(-0.3, 0.3), _rng.randf_range(0, TAU), _rng.randf_range(-0.3, 0.3)))
	if _rng.randf() < 0.5:
		_crystal(center + Vector3(0, size.y / 2.0, 0), Vector3.UP)


func _outcrop(seg: Dictionary, z: float) -> void:
	var side := -1.0 if _rng.randf() < 0.5 else 1.0
	var w: float = seg.width
	var reach := _rng.randf_range(3.0, 7.0)
	var y := _rng.randf_range(4.0, float(seg.ceiling) - 6.0)
	_box("rock", Vector3(side * (w / 2.0 - reach / 2.0 + 1.0), y, z),
			Vector3(reach + 2.0, _rng.randf_range(2.0, 4.0), _rng.randf_range(4.0, 8.0)),
			Vector3(_rng.randf_range(-0.2, 0.2), _rng.randf_range(-0.3, 0.3), _rng.randf_range(-0.25, 0.25)))


## Ice wall across the hall with a slit to fly through. Ice: hooking the
## face would only smash the player into it.
func _gate(seg: Dictionary, z: float) -> void:
	var w: float = seg.width + 8.0
	var top: float = seg.ceiling + 4.0
	var hx: float = seg.gate[0]
	var hw: float = seg.gate[1]
	# A slit from the depth to just under the ceiling: steer through it
	# sideways. (A floor edge would catch the dip of a long swing.)
	var hh: float = float(seg.ceiling) - 3.0 - DEPTH_Y
	var hy: float = DEPTH_Y + hh / 2.0
	var thick := 3.0
	var left := hx - hw / 2.0
	var right := hx + hw / 2.0
	_box("ice", Vector3((-w / 2.0 + left) / 2.0, (DEPTH_Y + top) / 2.0, z), Vector3(left + w / 2.0, top - DEPTH_Y, thick), Vector3.ZERO)
	_box("ice", Vector3((right + w / 2.0) / 2.0, (DEPTH_Y + top) / 2.0, z), Vector3(w / 2.0 - right, top - DEPTH_Y, thick), Vector3.ZERO)
	_box("ice", Vector3(hx, (hy + hh / 2.0 + top) / 2.0, z), Vector3(hw + 0.5, top - hy - hh / 2.0, thick), Vector3.ZERO)
	# Crystals frame the hole: the way through is easy to see.
	for y in [LEDGE_Y + 4.0, float(seg.ceiling) - 6.0]:
		_crystal(Vector3(left + 0.5, y, z + thick / 2.0), Vector3(0, 0, 1))
		_crystal(Vector3(right - 0.5, y, z + thick / 2.0), Vector3(0, 0, 1))
	_island(Vector3(hx, float(seg.ceiling) - 9.0, z - 14.0))


func _lava(seg: Dictionary, z0: float, z1: float) -> void:
	var length := z0 - z1
	var mid := (z0 + z1) / 2.0
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(float(seg.width) + 10.0, 1.0, length + 1.0)
	box.material = MATERIALS.lava
	mesh.mesh = box
	mesh.position = Vector3(0, LAVA_Y, mid)
	_add(mesh, "Geometry/Lava%d" % _hall)
	var area := Area3D.new()
	var shape := CollisionShape3D.new()
	var bshape := BoxShape3D.new()
	bshape.size = Vector3(float(seg.width) + 10.0, 6.0, length)
	shape.shape = bshape
	area.add_child(shape)
	area.position = Vector3(0, LAVA_Y + 2.0, mid)
	_add(area, "KillZones/Lava%d" % _hall)
	var count := maxi(1, roundi(length / 30.0))
	for i in count:
		var light := OmniLight3D.new()
		light.light_color = Color(1, 0.35, 0.1)
		light.light_energy = 4.0
		light.omni_range = 34.0
		light.position = Vector3(0, LAVA_Y + 8.0, z0 - length * (i + 0.5) / count)
		light.set_script(FLICKER)
		light.set("amount", 0.15)
		light.set("speed", 3.0)
		_add(light, "Lights/LavaLight%d_%d" % [_hall, i])


func _checkpoint(seg: Dictionary, z: float) -> void:
	_ledge(Vector3(0, LEDGE_Y, z), Vector3(9.0, 3.0, 9.0))
	var area := Area3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(float(seg.width) + 10.0, float(seg.ceiling) - DEPTH_Y, 2.0)
	shape.shape = box
	area.add_child(shape)
	area.position = Vector3(0, (DEPTH_Y + float(seg.ceiling)) / 2.0, z)
	var respawn := Marker3D.new()
	respawn.name = "Respawn"
	area.add_child(respawn)
	respawn.position = Vector3(0, LEDGE_Y + 1.0 - area.position.y, 0)
	var index := _level.get_node("Checkpoints").get_child_count()
	_add(area, "Checkpoints/Checkpoint%d" % index)
	_banner(Vector3(0, LEDGE_Y + 0.1, z + 4.4), Color(1.0, 0.85, 0.2), Vector3(8.0, 0.15, 0.15))
	_warm_light(Vector3(0, LEDGE_Y + 5.0, z))


func _finish(seg: Dictionary, z: float) -> void:
	_walls(seg, z, z - 16.0)
	_ceiling(seg, z, z - 16.0)
	_ledge(Vector3(0, LEDGE_Y, z - 6.0), Vector3(14.0, 4.0, 16.0))
	_box("rock_dark", Vector3(0, (DEPTH_Y + float(seg.ceiling)) / 2.0, z - 17.0),
			Vector3(float(seg.width) + 20.0, float(seg.ceiling) - DEPTH_Y + 20.0, 6.0), Vector3.ZERO)
	var area := Area3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(float(seg.width) + 10.0, float(seg.ceiling) - DEPTH_Y, 2.0)
	shape.shape = box
	area.add_child(shape)
	area.position = Vector3(0, (DEPTH_Y + float(seg.ceiling)) / 2.0, z)
	_add(area, "Finish")
	# Glowing gate frame over the finish ledge.
	var marker := Node3D.new()
	_add(marker, "FinishMarker")
	var green := Color(0.2, 0.85, 0.4)
	for side in [-1.0, 1.0]:
		_banner(Vector3(side * 6.0, LEDGE_Y + 5.0, z), green, Vector3(0.4, 10.0, 0.4), marker)
	_banner(Vector3(0, LEDGE_Y + 10.0, z), green, Vector3(12.4, 0.4, 0.4), marker)
	var light := OmniLight3D.new()
	light.light_color = green
	light.light_energy = 3.0
	light.omni_range = 20.0
	light.position = Vector3(0, LEDGE_Y + 6.0, z + 2.0)
	marker.add_child(light)


# --- Pieces ----------------------------------------------------------------------

## Flat rock ledge to stand on; top at pos.y.
func _ledge(pos: Vector3, size: Vector3) -> void:
	_box("rock_floor", pos - Vector3(0, size.y / 2.0, 0), size, Vector3.ZERO)
	# Rough underside hanging into the depth.
	_box("rock_dark", pos - Vector3(0, size.y + 2.5, 0), size * Vector3(0.7, 1.5, 0.7),
			Vector3(_rng.randf_range(-0.2, 0.2), _rng.randf_range(0, TAU), _rng.randf_range(-0.2, 0.2)))


func _crystal_on_wall(seg: Dictionary, z: float) -> void:
	var side := -1.0 if _rng.randf() < 0.5 else 1.0
	var y := _rng.randf_range(2.0, float(seg.ceiling) - 4.0)
	var x: float = side * (float(seg.width) / 2.0 - 1.5)
	_crystal(Vector3(x, y, z), Vector3(-side, 0.3, 0).normalized(), _rng.randf_range(1.5, 3.0))


## Glowing crystal cluster, size `scale` (big ones are landmarks).
func _crystal(pos: Vector3, up: Vector3, scale := 1.0) -> void:
	var crystal: Node3D = CRYSTAL.instantiate()
	var basis := Basis()
	basis.y = up.normalized()
	basis.x = basis.y.cross(Vector3.FORWARD if absf(basis.y.z) < 0.9 else Vector3.RIGHT).normalized()
	basis.z = basis.x.cross(basis.y).normalized()
	var spin := Basis(basis.y, _rng.randf_range(0, TAU))
	crystal.transform = Transform3D((spin * basis).scaled_local(Vector3.ONE * scale), pos)
	var glow: OmniLight3D = crystal.get_node("Glow")
	glow.omni_range *= sqrt(scale)
	_add(crystal, "Props/Crystal")


func _shaft(top: Vector3) -> void:
	var shaft: Node3D = SHAFT.instantiate()
	shaft.position = top
	_add(shaft, "Props/Shaft")
	var light := OmniLight3D.new()
	light.light_color = Color(0.75, 0.82, 1.0)
	light.light_energy = 1.6
	light.omni_range = 24.0
	light.position = top + Vector3(0, -10.0, 0)
	_add(light, "Lights/ShaftLight")


func _warm_light(pos: Vector3) -> void:
	var light := OmniLight3D.new()
	light.light_color = Color(1, 0.65, 0.35)
	light.light_energy = 2.0
	light.omni_range = 16.0
	light.position = pos
	light.set_script(FLICKER)
	_add(light, "Lights/Warm")


func _banner(pos: Vector3, color: Color, size: Vector3, parent: Node = null) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 1.5
	box.material = mat
	mesh.mesh = box
	mesh.position = pos
	if parent:
		parent.add_child(mesh)
	else:
		_add(mesh, "Props/Banner")


func _mover(pos: Vector3, size: Vector3, travel: Vector3, period: float, phase: float) -> void:
	var body := AnimatableBody3D.new()
	body.set_script(MOVER)
	body.set("travel", travel)
	body.set("period", period)
	body.set("phase", phase)
	body.position = pos
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	var mesh := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	bm.material = MATERIALS.metal
	mesh.mesh = bm
	body.add_child(mesh)
	_add(body, "Movers/Mover")


## One rock block: collision in the hall's static body (ice: the no-hook body),
## mesh as an instance of the hall's multimesh for its material.
func _box(material: String, pos: Vector3, size: Vector3, rotation: Vector3) -> void:
	_box_basis(material, pos, size, Basis.from_euler(rotation))


func _box_basis(material: String, pos: Vector3, size: Vector3, basis: Basis) -> void:
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.transform = Transform3D(basis, pos)
	(_ice_body if material == "ice" else _body).add_child(shape)
	if not _meshes.has(material):
		_meshes[material] = []
	_meshes[material].append(Transform3D(basis.scaled_local(size), pos))


func _begin_hall() -> void:
	_meshes = {}
	_body = StaticBody3D.new()
	_ice_body = StaticBody3D.new()
	_ice_body.add_to_group(NO_HOOK_GROUP)


func _end_hall() -> void:
	var geometry := _level.get_node("Geometry")
	_body.name = "Hall%d" % _hall
	geometry.add_child(_body)
	if _ice_body.get_child_count() > 0:
		_ice_body.name = "Ice%d" % _hall
		geometry.add_child(_ice_body)
	else:
		_ice_body.free()
	var unit := BoxMesh.new()
	for material: String in _meshes:
		var transforms: Array = _meshes[material]
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.mesh = unit
		multimesh.instance_count = transforms.size()
		for i in transforms.size():
			multimesh.set_instance_transform(i, transforms[i])
		var instance := MultiMeshInstance3D.new()
		instance.multimesh = multimesh
		instance.material_override = MATERIALS[material]
		instance.name = "Hall%d_%s" % [_hall, material]
		geometry.add_child(instance)
	_hall += 1


## Adds node under the level at path ("Group/Name": the name gets a number
## if taken).
func _add(node: Node, path: String) -> void:
	var parent: Node = _level
	var node_name := path
	var slash := path.rfind("/")
	if slash >= 0:
		parent = _level.get_node(path.substr(0, slash))
		node_name = path.substr(slash + 1)
	node.name = node_name
	parent.add_child(node, true)
