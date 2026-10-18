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
	"brittle": preload("res://assets/materials/brittle.tres"),
	"ice": preload("res://assets/materials/ice.tres"),
	"metal": preload("res://assets/materials/metal.tres"),
	"lava": preload("res://assets/materials/lava.tres"),
	"moss": preload("res://assets/materials/moss.tres"),
	"slick": preload("res://assets/materials/slick.tres"),
	"floater": preload("res://assets/materials/floater.tres"),
	"root": preload("res://assets/materials/root.tres"),
	"cap": preload("res://assets/materials/cap.tres"),
	"amber": preload("res://assets/materials/amber.tres"),
}
const CRYSTAL := preload("res://scenes/props/crystal.tscn")
const SHAFT := preload("res://scenes/props/light_shaft.tscn")
const MOVER := preload("res://scripts/mover.gd")
const FLICKER := preload("res://scripts/flicker.gd")
const UPDRAFT := preload("res://scripts/updraft.gd")
const BRITTLE := preload("res://scripts/brittle.gd")
const SPEED_RING := preload("res://scripts/speed_ring.gd")
const FLOATER := preload("res://scripts/floater.gd")
const BOUNCER := preload("res://scripts/bouncer.gd")
const AMBIENT := preload("res://scripts/ambient_sound.gd")
const SOUNDS := {
	"lava": preload("res://assets/sounds/amb_lava.wav"),
	"updraft": preload("res://assets/sounds/amb_updraft.wav"),
	"crystal": preload("res://assets/sounds/amb_crystal.wav"),
	"drip": preload("res://assets/sounds/drip.wav"),
	"water": preload("res://assets/sounds/amb_water.wav"),
}
const WATERFALL_SHADER := preload("res://shaders/waterfall.gdshader")
const SKY_SHADER := preload("res://shaders/sky.gdshader")
const NOISE_TEXTURE := preload("res://assets/textures/lava_noise.png")
## Chance that a hall (not lava, not open) has a waterfall down a wall.
const WATERFALL_CHANCE := 0.45
## Water drips per hall, falling from the ceiling.
const DRIPS_PER_HALL := 2
const NO_HOOK_GROUP := "no_hook"
## Beyond these distances (m) the fog has nearly swallowed things: they are
## not drawn at all (props are small, a hall is long so it reaches further).
const PROP_VISIBLE_RANGE := 120.0
const HALL_VISIBLE_RANGE := 230.0

## Top of the ledges (start, checkpoints, finish).
const LEDGE_Y := 0.0
## Walls and pillars reach down to here; below is only fog.
const DEPTH_Y := -60.0
## How hard the test bot steers to a lane (per meter off it): the slit of a
## gate, the way round a barrier, the middle of a shifted hall.
const GATE_PULL := 0.6
const HALL_PULL := 0.2
## Thickness of a shortcut barrier (m): the tube through it is this long.
const BARRIER_THICK := 10.0
## Top of the rock column under a bounce mushroom in a hall without floor.
const BOUNCER_COLUMN_TOP := -4.0
## Lava lakes lie this deep.
const LAVA_Y := -24.0
## How far the drawn rock of ceiling and walls may stand out from or sink
## into the flat collision (m): rough to look at, smooth to fly along.
const CEILING_ROUGHNESS := 0.4
const WALL_ROUGHNESS := 0.4
## Longest stalactite (m): longer ones cut through the swing.
const STALACTITE_MAX := 8.0
## Open halls: the far vault (no hook) this high above the ceiling height.
const OPEN_HEIGHT := 40.0
## Halls at least this wide get a line of ceiling crystals down the middle.
const WIDE_HALL := 50.0

const SEGMENT_DEFAULTS := {
	"length": 60.0,
	"width": 40.0,
	## Ceiling height above the ledges.
	"ceiling": 26.0,
	## "abyss" (nothing below), "ground" (rock floor at ledge height) or "lava".
	"floor": "abyss",
	## Stalactites per 10 m (obstacles more than targets: the whole ceiling
	## holds the hook).
	"stalactites": 0.3,
	"pillars": 0,
	"islands": 0,
	## Outcrops on the walls per 10 m (hook targets at the sides).
	"outcrops": 0.15,
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
	## Columns of rising air from the depth.
	"updrafts": 0,
	## Share of the stalactites that are brittle: they hold the hook briefly,
	## then break off (pale sandstone).
	"brittle": 0.0,
	## Glowing speed rings in the air (optional boosts).
	"rings": 0,
	## Dark hall: no light shafts, the ambient light dims, the head lamp goes on.
	"dark": false,
	## Open ceiling: no rock to hook above, only a far vault (no hook). The
	## way on is along floating stones.
	"open": false,
	## Floating stones every this many meters (0 = none), in a zigzag lane at
	## floater_height (m above the ledges; -1 = 4 m below the ceiling height).
	"floater_spacing": 0.0,
	"floater_height": -1.0,
	"floater_size": 3.5,
	## Walls of wet, slick rock: the hook does not hold on them.
	"slick_walls": false,
	## A hall template (TEMPLATES) whose values this hall starts from.
	"template": "",
	## Giant bounce mushrooms (Bouncer) along the hall: on the floor of a
	## ground hall, on a rock column from the depth elsewhere.
	"bouncers": 0,
	## Sideways offset of the hall's middle (m, +x is right): halls with
	## different shifts make the cave wind.
	"shift": 0.0,
	## Shortcut: a rock barrier across the middle of the hall with a wide way
	## round at one side and a tube of this size (m) straight through the
	## middle - shorter, but tight. 0 = no barrier.
	"shortcut": 0.0,
}
## Keys added after round 5: Level.version() leaves them out while they are
## at their default, so a new key does not reset every record.
const LATE_KEYS := ["bouncers", "shift", "shortcut"]

## Hall templates, built on the Wide Cave (wide, high, few obstacles): a hall
## names one with "template", its own keys win. Each has a clear job.
const TEMPLATES := {
	# Start and end: a ground hall to stand and land in.
	"start": {"length": 40.0, "width": 50.0, "ceiling": 28.0, "floor": "ground", "stalactites": 0.1,
		"outcrops": 0.0, "crystals": 2, "shafts": 1},
	# Long and high: swing at full speed.
	"sprint": {"length": 90.0, "width": 70.0, "ceiling": 34.0, "stalactites": 0.1, "outcrops": 0.1,
		"crystals": 4, "shafts": 2},
	# Columns to swing around.
	"slalom": {"length": 80.0, "width": 70.0, "ceiling": 32.0, "pillars": 4, "stalactites": 0.1,
		"outcrops": 0.05, "crystals": 3, "shafts": 1},
	# Very high and wide, rock islands: room for big arcs.
	"cathedral": {"length": 80.0, "width": 90.0, "ceiling": 46.0, "islands": 2, "stalactites": 0.1,
		"crystals": 5, "shafts": 3},
	# Narrow and low: precise throws (entered over slanted slabs).
	"narrows": {"length": 50.0, "width": 44.0, "ceiling": 24.0, "stalactites": 0.2, "outcrops": 0.2,
		"crystals": 2, "shafts": 1},
	# Open ceiling, slick walls: along the floating stones only.
	"skyway": {"length": 90.0, "width": 70.0, "ceiling": 30.0, "open": true, "floater_spacing": 16.0,
		"slick_walls": true, "stalactites": 0.0, "outcrops": 0.0, "crystals": 2, "shafts": 0},
	"lava_lake": {"length": 80.0, "width": 70.0, "ceiling": 34.0, "floor": "lava", "islands": 2,
		"stalactites": 0.15, "crystals": 3, "shafts": 1},
	"ice_vault": {"length": 80.0, "width": 70.0, "ceiling": 34.0, "ice": 0.9, "stalactites": 0.1,
		"outcrops": 0.15, "crystals": 3, "shafts": 1},
}

var _level: Node3D
var _rng := RandomNumberGenerator.new()
## Per hall: material name -> Array of [Transform3D (scaled unit box)].
var _meshes := {}
## Per hall: "kind|variant|material" -> Array of Transform3D (RockMesh models).
var _models := {}
var _body: StaticBody3D
var _ice_body: StaticBody3D
var _hall := 0
## Sideways offset (m) of the hall being built: every piece moves by it.
var _shift := 0.0
var _prev_shift := 0.0


## Builds the whole cave into level. Returns the z of the finish line.
func build(level: Node3D, segments: Array, seed_value: int) -> float:
	_level = level
	_rng.seed = seed_value
	for group in ["Geometry", "Props", "Lights", "Movers", "KillZones", "Checkpoints", "Dynamic", "Sounds"]:
		_add(Node3D.new(), group)

	var z := 0.0
	var first: Dictionary = _segment(segments[0] if not segments.is_empty() else {})
	_shift = float(first.shift)
	var start := Marker3D.new()
	start.position = Vector3(0, LEDGE_Y + 1.0, 0)
	_add(start, "Start")
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
		# The way between two halls is built in cave coordinates.
		_shift = 0.0
		_transition(prev, seg, z)
		_shift = float(seg.shift)
		_prev_shift = float(prev.shift)
		_build_hall(seg, z)
		_end_hall()
		z -= float(seg.length)
		prev = seg

	var last: Dictionary = _segment(segments[-1] if not segments.is_empty() else {})
	_shift = float(last.shift)
	_begin_hall()
	_finish(last, z)
	_end_hall()
	_shift = 0.0
	return z


func _segment(raw: Dictionary) -> Dictionary:
	return full_segment(raw)


## A hall with every key: the defaults, its template, its own keys.
static func full_segment(raw: Dictionary) -> Dictionary:
	var seg := SEGMENT_DEFAULTS.duplicate(true)
	seg.merge(TEMPLATES.get(raw.get("template", ""), {}).duplicate(true), true)
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
			_box("moss", Vector3(0, (LEDGE_Y + DEPTH_Y) / 2.0, (z0 + z1) / 2.0),
					Vector3(seg.width + 6.0, LEDGE_Y - DEPTH_Y, length + 0.5), Vector3.ZERO)
		"lava":
			_lava(seg, z0, z1)
	if seg.checkpoint:
		_checkpoint(seg, z0 - 6.0)

	var w: float = seg.width
	var c: float = seg.ceiling
	for i in roundi(float(seg.stalactites) * length / 10.0):
		var top := Vector3(_rng.randf_range(-w / 2.0 + 5.0, w / 2.0 - 5.0), c, _rng.randf_range(z1 + 3.0, z0 - 3.0))
		# Short: they decorate the ceiling instead of blocking the flight.
		var hang := _rng.randf_range(3.0, minf(STALACTITE_MAX, c - 6.0))
		# Only halls with brittle ones roll for it: other caves stay as they were.
		if float(seg.brittle) > 0.0 and _rng.randf() < float(seg.brittle):
			_brittle_stalactite(top, hang)
		else:
			_stalactite(top, hang, seg.ice_stalactites)
	for i in int(seg.updrafts):
		_updraft(Vector3(_rng.randf_range(-w / 2.0 + 8.0, w / 2.0 - 8.0), 0, z0 - length * (i + 0.5) / float(seg.updrafts)), c)
	for i in int(seg.rings):
		# On the ideal line: near the middle, at the height swings pass.
		_ring(Vector3(_rng.randf_range(-w / 3.0, w / 3.0) * 0.25, c * lerpf(0.55, 0.65, (_rng.randf_range(0.45, 0.7) - 0.45) / 0.25),
				z0 - length * (i + 0.5) / float(seg.rings)))
	if seg.dark and _level.has_method("add_dark_range"):
		_level.add_dark_range(z0, z1)
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
	for i in (0 if seg.dark else int(seg.shafts)):
		_shaft(Vector3(_rng.randf_range(-w / 3.0, w / 3.0), c, z0 - length * (i + 0.5) / float(seg.shafts)))
	if not (seg.gate as Array).is_empty():
		_gate(seg, z0 - length / 2.0)
		_lane(z0 - length / 2.0, float(seg.gate[0]), GATE_PULL)
	if float(seg.shortcut) > 0.0:
		_barrier(seg, z0 - length * 0.55)
	if absf(float(seg.shift)) > 0.5 or absf(_prev_shift) > 0.5:
		# A winding cave: the way leads to the middle of each hall.
		_lane(z0 - length * 0.3, 0.0, HALL_PULL)
	for b in seg.blocks:
		_box(b[6], Vector3(b[0], b[1], z0 - b[2]), Vector3(b[3], b[4], b[5]), Vector3.ZERO)
	_drips(seg, z0, z1)
	_decorate(seg, z0, z1)
	if float(seg.floater_spacing) > 0.0:
		_floaters(seg, z0, z1)
	if int(seg.bouncers) > 0:
		_bouncers(seg, z0, z1)
	for m in seg.movers:
		_mover(Vector3(m[0], m[1], z0 - m[2]), Vector3(m[3], m[4], m[5]), m[6], m[7], m[8])


## Where the next hall is lower or narrower, a slanted slab leads into it:
## a flat step would stop the player dead, a slope redirects the flight.
## Halls may sit sideways from each other (shift): each side wall on its own
## either narrows in (slanted slab) or steps out (a frame closes the gap).
## Built in cave coordinates (_shift is 0 here).
func _transition(prev: Dictionary, next: Dictionary, z: float) -> void:
	var s1 := float(prev.shift)
	var s2 := float(next.shift)
	var w1 := float(prev.width)
	var w2 := float(next.width)
	# Outer edges of both openings together.
	var left := minf(s1 - w1 / 2.0, s2 - w2 / 2.0)
	var right := maxf(s1 + w1 / 2.0, s2 + w2 / 2.0)
	# Out of an open hall the slope starts just above the floating stones,
	# not at the far vault (that would roof over the whole hall).
	var from := float(prev.ceiling) + (4.0 if prev.open else 0.0)
	var drop := from - float(next.ceiling)
	if prev.open != next.open:
		# Between an open hall and a closed one: a wall from the lower ceiling
		# up to the vault (no hook), so nothing is open above the closed hall.
		var low := minf(_top(prev), _top(next))
		var high := maxf(_top(prev), _top(next)) + 12.0
		var wide := right - left + 20.0
		var mid := (left + right) / 2.0
		_solid("ice", Vector3(mid, (low + high) / 2.0 + 3.0, z), Vector3(wide, high - low - 6.0, 4.0))
		_shape("rock_dark", Vector3(mid, (low + high) / 2.0 + 3.0, z), Vector3(wide, high - low - 6.0, 6.0), Vector3.ZERO)
	# Into a wider (or sideways) or higher hall: close the frame around the
	# smaller opening, or the space behind its walls and above its lid stays open.
	var top := _top(next) + 12.0
	# (Same order of pieces as before halls could shift: unshifted caves keep
	# their collision exactly.)
	for side: float in [-1.0, 1.0]:
		var edge1 := s1 + side * w1 / 2.0
		var edge2 := s2 + side * w2 / 2.0
		if side * (edge1 - edge2) < -0.5:
			var outer := edge2 + side * 8.0
			_box("rock_dark", Vector3((edge1 + outer) / 2.0, (DEPTH_Y + top) / 2.0, z + 2.0),
					Vector3(absf(outer - edge1), top - DEPTH_Y, 4.0), Vector3.ZERO)
	var rise := _top(next) - _top(prev)
	if rise > 0.5:
		# Above the lid, across where both openings overlap (the side frames
		# cover the rest).
		var low := minf(_top(prev), _top(next)) + 6.0
		var from_x := maxf(s1 - w1 / 2.0, s2 - w2 / 2.0) - 1.0
		var to_x := minf(s1 + w1 / 2.0, s2 + w2 / 2.0) + 1.0
		_box("rock_dark", Vector3((from_x + to_x) / 2.0, (low + top) / 2.0, z + 2.0), Vector3(to_x - from_x, top - low, 4.0), Vector3.ZERO)
	# Out of an open hall no slope: the stones fly below the next ceiling,
	# and a slab's top would be a ledge in the open air (nothing covers it).
	if drop > 0.5 and not prev.open:
		var run := maxf(drop * 2.5, 8.0)
		var face := Vector3(s1, from - drop / 2.0, z + run / 2.0)
		var along := Vector3(0, drop, run)
		_slab("rock_dark", face, Vector3(0, -run, drop).normalized(), along, w1 + 10.0, 8.0)
	for side: float in [-1.0, 1.0]:
		var edge1 := s1 + side * w1 / 2.0
		var edge2 := s2 + side * w2 / 2.0
		# > 0: the next wall stands further in on this side.
		var inward := side * (edge1 - edge2)
		if inward > 0.5:
			var run := maxf(inward * 2.5, 8.0)
			var face := Vector3((edge1 + edge2) / 2.0, (DEPTH_Y + _top(prev)) / 2.0, z + run / 2.0)
			var along := Vector3(edge1 - edge2, 0, run)
			var normal := Vector3(-side * run, 0, inward).normalized()
			_slab("rock", face, normal, along, _top(prev) - DEPTH_Y + 10.0, 8.0)


## Height of the rock above a hall: its ceiling, or the far vault if open.
func _top(seg: Dictionary) -> float:
	return float(seg.ceiling) + (OPEN_HEIGHT if seg.open else 0.0)


## Stops drawing node (and its meshes) beyond `distance` from the camera.
func _limit_range(node: Node, distance: float) -> void:
	var meshes: Array = node.find_children("*", "GeometryInstance3D", true, false)
	if node is GeometryInstance3D:
		meshes.append(node)
	for mesh: GeometryInstance3D in meshes:
		mesh.visibility_range_end = distance


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
## Only the look is rough: the collision is a flat face at the hall width,
## so sliding along a wall never catches on an edge.
func _walls(seg: Dictionary, z0: float, z1: float) -> void:
	var w: float = seg.width
	var top := _top(seg) + 12.0
	var slick: bool = seg.slick_walls
	for side in [-1.0, 1.0]:
		_solid("ice" if slick else "rock", Vector3(side * (w / 2.0 + 4.0), (DEPTH_Y + top) / 2.0, (z0 + z1) / 2.0),
				Vector3(8.0, top - DEPTH_Y, z0 - z1))
	var z := z0
	var n := 0
	while z > z1 + 0.1:
		var piece := minf(_rng.randf_range(7.0, 13.0), z - z1)
		for side in [-1.0, 1.0]:
			var thick := _rng.randf_range(4.0, 8.0)
			# Never more than WALL_ROUGHNESS in front of the flat face.
			var x: float = side * (w / 2.0 + thick / 2.0 + _rng.randf_range(-1.5, 1.5) / 1.5 * WALL_ROUGHNESS)
			var tilt := Vector3(_rng.randf_range(-0.05, 0.05), _rng.randf_range(-0.15, 0.15), _rng.randf_range(-0.08, 0.08))
			var material := "slick" if slick else ("rock" if n % 2 == 0 else "rock_dark")
			_shape(material, Vector3(x, (DEPTH_Y + top) / 2.0, z - piece / 2.0),
					Vector3(thick, top - DEPTH_Y, piece + 3.0), tilt * 0.2)
			n += 1
		z -= piece


## Ceiling from big blocks at slightly different heights: a rough vault to
## look at. To fly along, it is flat: one collision box per block, all with
## their underside at the ceiling height, so there is no edge to catch on.
## Ice blocks (no hook) stay ice in the collision, too.
func _ceiling(seg: Dictionary, z0: float, z1: float) -> void:
	if seg.open:
		_vault(seg, z0, z1)
		return
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
			# -2..1 m drawn as before (same random numbers), shown within
			# CEILING_ROUGHNESS of the flat underside.
			var bottom := c + (_rng.randf_range(-2.0, 1.0) + 2.0) / 3.0 * (CEILING_ROUGHNESS * 2.0) - CEILING_ROUGHNESS
			var ice := _rng.randf() < float(seg.ice)
			var material := "ice" if ice else ("rock_dark" if (i + int(z)) % 3 == 0 else "rock")
			_solid("ice" if ice else "rock", Vector3(x, c + 3.0, z - piece / 2.0), Vector3(col_w, 6.0, piece))
			var tilt := Vector3(_rng.randf_range(-0.06, 0.06), _rng.randf_range(-0.2, 0.2), _rng.randf_range(-0.06, 0.06))
			_shape(material, Vector3(x, bottom + thick / 2.0, z - piece / 2.0), Vector3(col_w + 3.0, thick, piece + 3.0),
					tilt * Vector3(0.25, 1.0, 0.25))
		z -= piece

func _stalactite(top: Vector3, length: float, ice: bool) -> void:
	var thick := _rng.randf_range(1.6, 3.0)
	var tilt := Vector3(_rng.randf_range(-0.08, 0.08), _rng.randf_range(0, TAU), _rng.randf_range(-0.08, 0.08))
	var mat := "ice" if ice else "rock"
	# Collision: upper body and a narrower tip. Drawn: a tapering cone.
	_collider(mat, top + Vector3(0, -length * 0.35 + 1.0, 0), Vector3(thick, length * 0.7, thick), tilt)
	_collider(mat, top + Vector3(0, -length * 0.8 + 1.0, 0), Vector3(thick * 0.55, length * 0.4, thick * 0.55), tilt)
	_model("stalactite", mat, Transform3D(Basis.from_euler(tilt).scaled_local(Vector3(thick * 1.3, length + 1.0, thick * 1.3)),
			top + Vector3(0, 1.0, 0)))


## A stalactite that breaks off a moment after the hook bites: its own
## moving body (not part of the hall), in pale sandstone to tell it apart.
func _brittle_stalactite(top: Vector3, length: float) -> void:
	var body := AnimatableBody3D.new()
	body.set_script(BRITTLE)
	body.position = top
	var thick := _rng.randf_range(1.6, 2.6)
	for part in [[Vector3(0, -length * 0.35 + 1.0, 0), Vector3(thick, length * 0.7, thick)],
			[Vector3(0, -length * 0.8 + 1.0, 0), Vector3(thick * 0.55, length * 0.4, thick * 0.55)]]:
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = part[1]
		shape.shape = box
		shape.position = part[0]
		body.add_child(shape)
		var mesh := MeshInstance3D.new()
		var box_mesh := BoxMesh.new()
		box_mesh.size = part[1]
		box_mesh.material = MATERIALS.brittle
		mesh.mesh = box_mesh
		mesh.position = part[0]
		mesh.visibility_range_end = PROP_VISIBLE_RANGE
		body.add_child(mesh)
	_add(body, "Dynamic/Brittle")


## A column of rising air from the depth up to below the ceiling, with wisps.
func _updraft(base: Vector3, ceiling: float) -> void:
	var area := Area3D.new()
	area.set_script(UPDRAFT)
	var height := ceiling - 4.0 - DEPTH_Y
	area.position = Vector3(base.x, DEPTH_Y + height / 2.0, base.z)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(7.0, height, 7.0)
	shape.shape = box
	area.add_child(shape)
	var wisps := CPUParticles3D.new()
	wisps.amount = 40
	wisps.lifetime = 3.0
	wisps.preprocess = 3.0
	wisps.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	wisps.emission_box_extents = Vector3(3.0, height * 0.35, 3.0)
	wisps.position = Vector3(0, -height * 0.1, 0)
	wisps.direction = Vector3.UP
	wisps.spread = 8.0
	wisps.gravity = Vector3.ZERO
	wisps.initial_velocity_min = 10.0
	wisps.initial_velocity_max = 16.0
	wisps.particle_flag_align_y = true
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.albedo_color = Color(0.6, 0.85, 1.0, 0.35)
	var streak := BoxMesh.new()
	streak.size = Vector3(0.05, 1.6, 0.05)
	streak.material = material
	wisps.mesh = streak
	wisps.visibility_range_end = PROP_VISIBLE_RANGE
	area.add_child(wisps)
	_add(area, "Dynamic/Updraft")
	var light := OmniLight3D.new()
	light.light_color = Color(0.55, 0.8, 1.0)
	light.light_energy = 1.2
	light.omni_range = 16.0
	light.position = Vector3(base.x, ceiling * 0.4, base.z)
	_ambient("updraft", light.position, 45.0, -2.0)
	_add(light, "Lights/Updraft")


## A glowing ring facing down the cave (-Z): flying through it boosts.
func _ring(center: Vector3) -> void:
	var ring := Area3D.new()
	ring.set_script(SPEED_RING)
	ring.position = center
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = 2.4
	cylinder.height = 1.2
	shape.shape = cylinder
	shape.rotation = Vector3(PI / 2.0, 0, 0)
	ring.add_child(shape)
	var mesh := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 2.4
	torus.outer_radius = 2.8
	torus.rings = 24
	torus.ring_segments = 6
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.8, 0.25)
	material.emission_enabled = true
	material.emission = Color(1.0, 0.75, 0.2)
	material.emission_energy_multiplier = 2.0
	torus.material = material
	mesh.mesh = torus
	mesh.rotation = Vector3(PI / 2.0, 0, 0)
	mesh.visibility_range_end = HALL_VISIBLE_RANGE
	ring.add_child(mesh)
	_add(ring, "Dynamic/Ring")


## A column rising out of the depth, ending in a broken top below the ceiling
## (or reaching it).
func _pillar(base: Vector3, ceiling: float) -> void:
	var r := _rng.randf_range(1.8, 3.5)
	var top := ceiling + 2.0 if _rng.randf() < 0.5 else _rng.randf_range(4.0, ceiling - 8.0)
	var body := Vector3(base.x, (DEPTH_Y + top) / 2.0, base.z)
	var size := Vector3(r * 2.0, top - DEPTH_Y, r * 2.0)
	var turn := Vector3(0, _rng.randf_range(0, TAU), _rng.randf_range(-0.04, 0.04))
	_collider("rock", body, size, turn)
	_model("pillar", "rock", Transform3D(Basis.from_euler(turn).scaled_local(size * Vector3(1.2, 1.0, 1.2)), body))
	var cap := Vector3(base.x, top - 0.5, base.z)
	var cap_size := Vector3(r * 2.6, 2.0, r * 2.6)
	var cap_turn := Vector3(_rng.randf_range(-0.2, 0.2), _rng.randf_range(0, TAU), _rng.randf_range(-0.2, 0.2))
	_collider("rock_dark", cap, cap_size, cap_turn)
	_model("boulder", "moss", Transform3D(Basis.from_euler(cap_turn).scaled_local(cap_size * Vector3(1.15, 1.6, 1.15)), cap))


## Floating rock island: a flat-ish top and a jagged underside.
func _island(center: Vector3) -> void:
	var size := Vector3(_rng.randf_range(5.0, 9.0), _rng.randf_range(2.5, 4.0), _rng.randf_range(5.0, 9.0))
	var turn := Vector3(_rng.randf_range(-0.1, 0.1), _rng.randf_range(0, TAU), _rng.randf_range(-0.1, 0.1))
	_collider("rock", center, size, turn)
	_model("boulder", "moss", Transform3D(Basis.from_euler(turn).scaled_local(size * Vector3(1.25, 1.3, 1.25)), center))
	for i in 2:
		var s := size * Vector3(_rng.randf_range(0.35, 0.6), _rng.randf_range(0.8, 1.4), _rng.randf_range(0.35, 0.6))
		var pos := center + Vector3(_rng.randf_range(-1.5, 1.5), -size.y * 0.6, _rng.randf_range(-1.5, 1.5))
		var t := Vector3(_rng.randf_range(-0.3, 0.3), _rng.randf_range(0, TAU), _rng.randf_range(-0.3, 0.3))
		_collider("rock_dark", pos, s, t)
		# Drawn longer: a jagged, hanging underside.
		_model("stalactite", "rock_dark", Transform3D(Basis.from_euler(t).scaled_local(s * Vector3(1.3, 1.8, 1.3)),
				pos + Vector3(0, s.y * 0.6, 0)))
	if _rng.randf() < 0.5:
		_crystal(center + Vector3(0, size.y / 2.0, 0), Vector3.UP)
	else:
		_mushrooms(center + Vector3(0, size.y / 2.0, 0), 3)


func _outcrop(seg: Dictionary, z: float) -> void:
	var side := -1.0 if _rng.randf() < 0.5 else 1.0
	var w: float = seg.width
	var reach := _rng.randf_range(3.0, 7.0)
	var y := _rng.randf_range(4.0, float(seg.ceiling) - 6.0)
	var pos := Vector3(side * (w / 2.0 - reach / 2.0 + 1.0), y, z)
	var size := Vector3(reach + 2.0, _rng.randf_range(2.0, 4.0), _rng.randf_range(4.0, 8.0))
	var turn := Vector3(_rng.randf_range(-0.2, 0.2), _rng.randf_range(-0.3, 0.3), _rng.randf_range(-0.25, 0.25))
	_collider("slick" if seg.slick_walls else "rock", pos, size, turn)
	_model("boulder", "slick" if seg.slick_walls else "rock", Transform3D(Basis.from_euler(turn).scaled_local(size * 1.2), pos))


## Ice wall across the hall with a slit to fly through. Ice: hooking the
## face would only smash the player into it.
func _gate(seg: Dictionary, z: float) -> void:
	var w: float = seg.width + 8.0
	var top: float = seg.ceiling + 4.0
	var hx: float = seg.gate[0]
	var hw: float = seg.gate[1]
	# A slit from the depth up to the ceiling: steer through it sideways.
	# (A floor edge would catch the dip of a long swing, a beam under the
	# ceiling a slide along it.)
	var thick := 3.0
	var left := hx - hw / 2.0
	var right := hx + hw / 2.0
	_box("ice", Vector3((-w / 2.0 + left) / 2.0, (DEPTH_Y + top) / 2.0, z), Vector3(left + w / 2.0, top - DEPTH_Y, thick), Vector3.ZERO)
	_box("ice", Vector3((right + w / 2.0) / 2.0, (DEPTH_Y + top) / 2.0, z), Vector3(w / 2.0 - right, top - DEPTH_Y, thick), Vector3.ZERO)
	# Crystals frame the hole: the way through is easy to see.
	for y in [LEDGE_Y + 4.0, float(seg.ceiling) - 6.0]:
		_crystal(Vector3(left + 0.5, y, z + thick / 2.0), Vector3(0, 0, 1))
		_crystal(Vector3(right - 0.5, y, z + thick / 2.0), Vector3(0, 0, 1))
	_island(Vector3(hx, float(seg.ceiling) - 9.0, z - 14.0))


func _lava(seg: Dictionary, z0: float, z1: float) -> void:
	var length := z0 - z1
	var mid := (z0 + z1) / 2.0
	# A subdivided plane: the shader swells it slowly.
	var mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(float(seg.width) + 10.0, length + 1.0)
	plane.subdivide_width = int(plane.size.x / 4.0)
	plane.subdivide_depth = int(plane.size.y / 4.0)
	plane.material = MATERIALS.lava
	mesh.mesh = plane
	mesh.position = Vector3(0, LAVA_Y + 0.5, mid)
	_add(mesh, "Geometry/Lava%d" % _hall)
	# Embers rising from the lava.
	var embers := CPUParticles3D.new()
	embers.amount = 36
	embers.lifetime = 4.0
	embers.preprocess = 4.0
	embers.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	embers.emission_box_extents = Vector3(float(seg.width) / 2.0, 0.5, length / 2.0)
	embers.direction = Vector3.UP
	embers.spread = 25.0
	embers.gravity = Vector3(0, 1.5, 0)
	embers.initial_velocity_min = 1.5
	embers.initial_velocity_max = 4.0
	embers.scale_amount_min = 0.6
	embers.scale_amount_max = 1.4
	var fade := Gradient.new()
	fade.set_color(0, Color(1.0, 0.8, 0.3, 1.0))
	fade.set_color(1, Color(1.0, 0.2, 0.05, 0.0))
	embers.color_ramp = fade
	var ember_material := StandardMaterial3D.new()
	ember_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ember_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ember_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	ember_material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	ember_material.vertex_color_use_as_albedo = true
	var ember := QuadMesh.new()
	ember.size = Vector2(0.35, 0.35)
	ember.material = ember_material
	embers.mesh = ember
	embers.position = Vector3(0, LAVA_Y + 1.0, mid)
	_limit_range(embers, PROP_VISIBLE_RANGE)
	_add(embers, "Props/Embers")
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
		_ambient("lava", light.position, 70.0, 0.0)


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
	# Just in front of the back wall (its face is at z - 14).
	_daylight(seg, z - 13.4)
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


## The way out: daylight through an arch in the back wall behind the finish
## (a sky shader on a quad, a warm light pouring in, beams of light).
func _daylight(seg: Dictionary, z: float) -> void:
	var c: float = seg.ceiling
	var arch := Vector2(minf(float(seg.width) * 0.45, 26.0), minf(c - 4.0, 24.0))
	var sky_material := ShaderMaterial.new()
	sky_material.shader = SKY_SHADER
	sky_material.set_shader_parameter("noise", NOISE_TEXTURE)
	var quad := QuadMesh.new()
	quad.size = arch
	quad.material = sky_material
	var sky := MeshInstance3D.new()
	sky.name = "Sky"
	sky.mesh = quad
	sky.position = Vector3(0, LEDGE_Y + 2.0 + arch.y / 2.0, z)
	var exit := Node3D.new()
	exit.add_child(sky)
	# Beams falling in through the opening.
	for i in 3:
		var beam := MeshInstance3D.new()
		var beam_mesh := QuadMesh.new()
		beam_mesh.size = Vector2(arch.x * 0.25, 30.0)
		var beam_material := StandardMaterial3D.new()
		beam_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		beam_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		beam_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		beam_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		beam_material.albedo_texture = preload("res://assets/textures/light_shaft.png")
		beam_material.albedo_color = Color(1.0, 0.92, 0.7, 0.35)
		beam_mesh.material = beam_material
		beam.mesh = beam_mesh
		beam.position = Vector3((i - 1) * arch.x * 0.3, LEDGE_Y + arch.y * 0.6, z + 12.0)
		beam.basis = Basis(Vector3.RIGHT, -0.9)
		exit.add_child(beam)
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.9, 0.7)
	light.light_energy = 4.0
	light.omni_range = 45.0
	light.position = Vector3(0, LEDGE_Y + arch.y * 0.6, z + 6.0)
	_limit_range(exit, HALL_VISIBLE_RANGE)
	_add(exit, "Props/Daylight")
	_add(light, "Lights/Daylight")


# --- Pieces ----------------------------------------------------------------------

## Flat rock ledge to stand on; top at pos.y.
func _ledge(pos: Vector3, size: Vector3) -> void:
	_box("moss", pos - Vector3(0, size.y / 2.0, 0), size, Vector3.ZERO)
	# Rough underside hanging into the depth.
	var under := pos - Vector3(0, size.y + 2.5, 0)
	var under_size := size * Vector3(0.7, 1.5, 0.7)
	var turn := Vector3(_rng.randf_range(-0.2, 0.2), _rng.randf_range(0, TAU), _rng.randf_range(-0.2, 0.2))
	_collider("rock_dark", under, under_size, turn)
	_model("stalactite", "rock_dark", Transform3D(Basis.from_euler(turn).scaled_local(under_size * Vector3(1.4, 1.6, 1.4)),
			under + Vector3(0, under_size.y * 0.5, 0)))
	_mushrooms(pos + Vector3(size.x * 0.35, 0, size.z * 0.3), 4)


## The far vault of an open hall: rock high above that the hook does not
## hold (the way on is along the floating stones), with pale light falling in.
func _vault(seg: Dictionary, z0: float, z1: float) -> void:
	var w: float = seg.width
	var top := _top(seg)
	var rng := _deco_rng(17)
	_solid("ice", Vector3(0, top + 6.0, (z0 + z1) / 2.0), Vector3(w + 16.0, 12.0, z0 - z1))
	var z := z0
	while z > z1 + 0.1:
		var piece := minf(rng.randf_range(10.0, 16.0), z - z1)
		for i in 4:
			var x := -w / 2.0 + w * (i + 0.5) / 4.0
			var thick := rng.randf_range(6.0, 12.0)
			_shape("rock_dark", Vector3(x, top + thick / 2.0 - rng.randf_range(0.0, 3.0), z - piece / 2.0),
					Vector3(w / 4.0 + 4.0, thick, piece + 4.0), Vector3(rng.randf_range(-0.1, 0.1), rng.randf_range(-0.3, 0.3), 0))
		z -= piece
	for i in maxi(1, roundi((z0 - z1) / 30.0)):
		var at := Vector3(rng.randf_range(-w / 3.0, w / 3.0), top, z0 - (z0 - z1) * (i + 0.5) / maxi(1, roundi((z0 - z1) / 30.0)))
		_shaft(at, 2.4)


## Floating stones in a zigzag lane: hook one after the other and swing
## along. Missing one means falling into the depth.
func _floaters(seg: Dictionary, z0: float, z1: float) -> void:
	var rng := _deco_rng(29)
	var w: float = seg.width
	var spacing: float = seg.floater_spacing
	var band: float = seg.floater_height if float(seg.floater_height) >= 0.0 else float(seg.ceiling) - 4.0
	var swing := minf(w * 0.22, 10.0)
	var z := z0 - spacing * 0.6
	var i := 0
	while z > z1 + 2.0:
		var size: float = float(seg.floater_size) * rng.randf_range(0.8, 1.25)
		var pos := Vector3((1.0 if i % 2 == 0 else -1.0) * swing + rng.randf_range(-3.0, 3.0),
				band + rng.randf_range(-2.5, 2.5), z + rng.randf_range(-2.0, 2.0))
		var body := AnimatableBody3D.new()
		body.set_script(FLOATER)
		body.position = pos
		var shape := CollisionShape3D.new()
		var sphere := SphereShape3D.new()
		sphere.radius = size * 0.45
		shape.shape = sphere
		body.add_child(shape)
		var mesh := MeshInstance3D.new()
		mesh.mesh = RockMesh.get_mesh("boulder", i)
		mesh.material_override = MATERIALS.floater
		mesh.scale = Vector3(size, size * 0.85, size)
		mesh.rotation.y = rng.randf_range(0, TAU)
		mesh.visibility_range_end = PROP_VISIBLE_RANGE
		body.add_child(mesh)
		# A small stalactite of rock below: they float, but look heavy.
		var tail := MeshInstance3D.new()
		tail.mesh = RockMesh.get_mesh("stalactite", i + 1)
		tail.material_override = MATERIALS.rock_dark
		tail.scale = Vector3(size * 0.55, size * 0.9, size * 0.55)
		tail.position = Vector3(0, -size * 0.25, 0)
		tail.visibility_range_end = PROP_VISIBLE_RANGE
		body.add_child(tail)
		# Each stone lights itself and its neighbourhood: the lane is easy to
		# read in the dark open hall.
		var light := OmniLight3D.new()
		light.light_color = Color(0.45, 0.85, 1.0)
		light.light_energy = 2.2
		light.omni_range = 15.0
		light.position = Vector3(0, size * 0.9, 0)
		body.add_child(light)
		_add(body, "Dynamic/Floater")
		z -= spacing
		i += 1


## Decoration with its own random numbers (the cave layout stays the same):
## roots hanging from the ceiling, a line of ceiling crystals down the middle
## of wide halls, an amber beacon at the exit, mushrooms and stones on floors.
func _decorate(seg: Dictionary, z0: float, z1: float) -> void:
	var rng := _deco_rng(53)
	var w: float = seg.width
	var c: float = seg.ceiling
	var length := z0 - z1
	if not seg.open:
		for i in int(length / 9.0):
			var hang := rng.randf_range(2.5, 6.5)
			var thick := rng.randf_range(0.25, 0.55)
			var at := Vector3(rng.randf_range(-w / 2.0 + 2.0, w / 2.0 - 2.0), c + 0.6, rng.randf_range(z1 + 1.0, z0 - 1.0))
			var turn := Vector3(rng.randf_range(-0.25, 0.25), rng.randf_range(0, TAU), rng.randf_range(-0.25, 0.25))
			_model("root", "root", Transform3D(Basis.from_euler(turn).scaled_local(Vector3(thick, hang, thick)), at))
		if w >= WIDE_HALL:
			var z := z0 - 13.0
			var side := 1.0
			while z > z1 + 6.0:
				_crystal(Vector3(side * w * 0.12, c + 0.6, z), Vector3.DOWN, 2.2, rng)
				side = -side
				z -= 26.0
	if not seg.open and seg.floor != "lava":
		_waterfall(seg, z0, z1)
	# The way on: an amber beacon at the exit of the hall.
	var beacon_y := c - 1.0 if not seg.open else (float(seg.floater_height) if float(seg.floater_height) >= 0.0 else c - 4.0) + 7.0
	_beacon(Vector3(0, beacon_y, z1 + 3.0), seg.open)
	if seg.floor == "ground":
		for i in 3:
			_mushrooms(Vector3(rng.randf_range(-w / 2.0 + 3.0, w / 2.0 - 3.0), LEDGE_Y, rng.randf_range(z1 + 3.0, z0 - 3.0)), 5)
		for i in int(length / 12.0):
			var size := rng.randf_range(0.8, 2.2)
			var at := Vector3(rng.randf_range(-w / 2.0 + 2.0, w / 2.0 - 2.0), LEDGE_Y - size * 0.25, rng.randf_range(z1 + 2.0, z0 - 2.0))
			_model("boulder", "rock", Transform3D(Basis(Vector3.UP, rng.randf_range(0, TAU)).scaled_local(Vector3(size, size * 0.7, size)), at))


## Now and then a waterfall pours down a wall from the ceiling into the depth
## (or onto the floor, with mist): a scrolling shader on a quad, no collision,
## and its rushing sound. Own random numbers.
func _waterfall(seg: Dictionary, z0: float, z1: float) -> void:
	var rng := _deco_rng(61)
	if rng.randf() > WATERFALL_CHANCE:
		return
	var w: float = seg.width
	var c: float = seg.ceiling
	var side := -1.0 if rng.randf() < 0.5 else 1.0
	var z := rng.randf_range(z1 + (z0 - z1) * 0.25, z0 - (z0 - z1) * 0.25)
	var width := rng.randf_range(7.0, 11.0)
	var bottom := LEDGE_Y if seg.floor == "ground" else DEPTH_Y + 20.0
	var height := c - bottom
	var material := ShaderMaterial.new()
	material.shader = WATERFALL_SHADER
	material.set_shader_parameter("noise", NOISE_TEXTURE)
	material.set_shader_parameter("height", height)
	material.set_shader_parameter("speed", rng.randf_range(0.7, 1.1))
	var sheet := QuadMesh.new()
	sheet.size = Vector2(width, height)
	sheet.material = material
	var fall := MeshInstance3D.new()
	fall.mesh = sheet
	# Facing into the hall, a little off the rough wall.
	fall.basis = Basis(Vector3.UP, -side * PI / 2.0)
	fall.position = Vector3(side * (w / 2.0 - 1.2), (c + bottom) / 2.0, z)
	_limit_range(fall, HALL_VISIBLE_RANGE)
	_add(fall, "Props/Waterfall")
	var mist := CPUParticles3D.new()
	mist.amount = 24
	mist.lifetime = 2.5
	mist.preprocess = 2.5
	mist.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	mist.emission_box_extents = Vector3(1.0, 0.5, width / 2.0)
	mist.direction = Vector3(-side, 0.6, 0)
	mist.spread = 35.0
	mist.gravity = Vector3(0, 0.4, 0)
	mist.initial_velocity_min = 1.0
	mist.initial_velocity_max = 3.0
	mist.scale_amount_min = 2.0
	mist.scale_amount_max = 4.0
	var fade := Gradient.new()
	fade.set_color(0, Color(0.85, 0.92, 1.0, 0.35))
	fade.set_color(1, Color(0.85, 0.92, 1.0, 0.0))
	mist.color_ramp = fade
	var mist_material := StandardMaterial3D.new()
	mist_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mist_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mist_material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mist_material.vertex_color_use_as_albedo = true
	mist_material.albedo_texture = preload("res://assets/textures/dust.png")
	var puff := QuadMesh.new()
	puff.size = Vector2(1.0, 1.0)
	puff.material = mist_material
	mist.mesh = puff
	mist.position = Vector3(side * (w / 2.0 - 2.0), bottom + 1.0, z)
	_limit_range(mist, PROP_VISIBLE_RANGE)
	_add(mist, "Props/Mist")
	_ambient("water", Vector3(side * (w / 2.0 - 2.0), c * 0.5, z), 55.0, -3.0)


## Random numbers for decoration only: seeded from the cave and the hall, so
## decorations never shift the layout (or each other).
func _deco_rng(salt: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = _rng.seed + _hall * 7919 + salt * 104729
	return rng


## Warm amber crystals marking the exit of a hall (hanging from the ceiling,
## or floating in an open hall).
func _beacon(pos: Vector3, floating: bool) -> void:
	var beacon: Node3D = CRYSTAL.instantiate()
	beacon.transform = Transform3D(Basis(Vector3.RIGHT, PI if not floating else 0.0).scaled(Vector3.ONE * 1.8), pos)
	for prism in beacon.find_children("Prism*", "MeshInstance3D", false, false):
		(prism as MeshInstance3D).material_override = MATERIALS.amber
	var glow: OmniLight3D = beacon.get_node("Glow")
	glow.light_color = Color(1.0, 0.62, 0.25)
	glow.light_energy = 2.4
	glow.omni_range = 22.0
	_limit_range(beacon, HALL_VISIBLE_RANGE)
	_add(beacon, "Props/Beacon")


## A cluster of glowing mushrooms standing on `pos` (decoration).
func _mushrooms(pos: Vector3, count: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = RockMesh.variant_at(pos)
	var cluster := Node3D.new()
	cluster.position = pos
	for i in count:
		var height := rng.randf_range(0.3, 1.1)
		var radius := rng.randf_range(0.25, 0.6)
		var at := Vector3(rng.randf_range(-1.2, 1.2), 0, rng.randf_range(-1.2, 1.2))
		var stem := MeshInstance3D.new()
		var stem_mesh := CylinderMesh.new()
		stem_mesh.top_radius = radius * 0.22
		stem_mesh.bottom_radius = radius * 0.3
		stem_mesh.height = height
		stem_mesh.radial_segments = 6
		stem_mesh.rings = 1
		stem.mesh = stem_mesh
		stem.material_override = MATERIALS.root
		stem.position = at + Vector3(0, height / 2.0, 0)
		cluster.add_child(stem)
		var cap := MeshInstance3D.new()
		var cap_mesh := SphereMesh.new()
		cap_mesh.radius = radius
		cap_mesh.height = radius
		cap_mesh.is_hemisphere = true
		cap_mesh.radial_segments = 8
		cap_mesh.rings = 3
		cap.mesh = cap_mesh
		cap.material_override = MATERIALS.cap
		cap.position = at + Vector3(0, height, 0)
		cluster.add_child(cap)
	var light := OmniLight3D.new()
	light.light_color = Color(0.4, 1.0, 0.8)
	light.light_energy = 0.9
	light.omni_range = 7.0
	light.position = Vector3(0, 1.2, 0)
	cluster.add_child(light)
	_limit_range(cluster, PROP_VISIBLE_RANGE)
	_add(cluster, "Props/Mushrooms")


## A sound at pos, audible up to max_distance. interval > 0 repeats a
## one-shot every interval .. 3 * interval seconds instead of looping.
func _ambient(sound: String, pos: Vector3, max_distance: float, volume_db: float, interval := 0.0) -> void:
	var player := AudioStreamPlayer3D.new()
	player.set_script(AMBIENT)
	player.stream = SOUNDS[sound]
	player.position = pos
	player.max_distance = max_distance
	player.unit_size = max_distance / 6.0
	player.volume_db = volume_db
	player.set("interval_min", interval)
	player.set("interval_max", interval * 3.0)
	_add(player, "Sounds/" + sound.capitalize())


## Drips from the ceiling. Their own random numbers: the cave layout stays
## the same as before they existed.
func _drips(seg: Dictionary, z0: float, z1: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _rng.seed + _hall * 7919
	var w: float = seg.width
	for i in DRIPS_PER_HALL:
		var pos := Vector3(rng.randf_range(-w / 3.0, w / 3.0), float(seg.ceiling) - 2.0, rng.randf_range(z1 + 4.0, z0 - 4.0))
		_ambient("drip", pos, 30.0, -4.0, 2.0)


func _crystal_on_wall(seg: Dictionary, z: float) -> void:
	var side := -1.0 if _rng.randf() < 0.5 else 1.0
	var y := _rng.randf_range(2.0, float(seg.ceiling) - 4.0)
	var x: float = side * (float(seg.width) / 2.0 - 1.5)
	_crystal(Vector3(x, y, z), Vector3(-side, 0.3, 0).normalized(), _rng.randf_range(1.5, 3.0))
	_ambient("crystal", Vector3(x, y, z), 18.0, -8.0)


## Glowing crystal cluster, size `scale` (big ones are landmarks).
## rng: decoration passes its own (the layout's random numbers stay put).
func _crystal(pos: Vector3, up: Vector3, scale := 1.0, rng: RandomNumberGenerator = null) -> void:
	var crystal: Node3D = CRYSTAL.instantiate()
	var basis := Basis()
	basis.y = up.normalized()
	basis.x = basis.y.cross(Vector3.FORWARD if absf(basis.y.z) < 0.9 else Vector3.RIGHT).normalized()
	basis.z = basis.x.cross(basis.y).normalized()
	var spin := Basis(basis.y, (rng if rng else _rng).randf_range(0, TAU))
	crystal.transform = Transform3D((spin * basis).scaled_local(Vector3.ONE * scale), pos)
	var glow: OmniLight3D = crystal.get_node("Glow")
	glow.omni_range *= sqrt(scale)
	_limit_range(crystal, PROP_VISIBLE_RANGE)
	_add(crystal, "Props/Crystal")


func _shaft(top: Vector3, length_scale := 1.0) -> void:
	var shaft: Node3D = SHAFT.instantiate()
	shaft.position = top
	shaft.scale = Vector3(length_scale, length_scale, length_scale)
	_limit_range(shaft, PROP_VISIBLE_RANGE)
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
	# Markers are landmarks: visible further than other props.
	mesh.visibility_range_end = HALL_VISIBLE_RANGE
	if parent:
		parent.add_child(mesh)
	else:
		_add(mesh, "Props/Banner")


## A lane the test bot steers to (Level.add_lane()), in hall coordinates.
func _lane(z: float, x: float, pull: float) -> void:
	if _level.has_method("add_lane"):
		_level.add_lane(z, x + _shift, pull)


## Shortcut: a rock barrier across the hall. The wide way round is at one
## side (a third of the width, full height); straight through the middle runs
## a tube of seg.shortcut meters - shorter, but miss it and you hit rock.
## Crystals ring the tube so it stands out. Own random numbers.
func _barrier(seg: Dictionary, z: float) -> void:
	var rng := _deco_rng(41)
	var w: float = seg.width
	var size: float = seg.shortcut
	var side := -1.0 if rng.randf() < 0.5 else 1.0
	var gap := w / 3.0
	var gap_x := side * (w / 2.0 - gap / 2.0)
	var tube := Vector2(-side * w * 0.08, float(seg.ceiling) * 0.5)
	var x0 := -w / 2.0 - 6.0
	var x1 := w / 2.0 + 6.0
	var y0 := DEPTH_Y
	var y1 := _top(seg) + 6.0
	# Cut the wall into strips between the openings' edges.
	var cuts := [x0, x1, gap_x - gap / 2.0, gap_x + gap / 2.0, tube.x - size / 2.0, tube.x + size / 2.0]
	cuts.sort()
	for i in cuts.size() - 1:
		var a: float = maxf(cuts[i], x0)
		var b: float = minf(cuts[i + 1], x1)
		if b - a < 0.05:
			continue
		var mid := (a + b) / 2.0
		if absf(mid - gap_x) < gap / 2.0:
			continue
		var spans := [[y0, y1]]
		if absf(mid - tube.x) < size / 2.0:
			spans = [[y0, tube.y - size / 2.0], [tube.y + size / 2.0, y1]]
		for span: Array in spans:
			_box("rock_dark", Vector3(mid, (span[0] + span[1]) / 2.0, z), Vector3(b - a, span[1] - span[0], BARRIER_THICK), Vector3.ZERO)
	for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		var at := Vector3(tube.x + corner.x * (size / 2.0 + 0.6), tube.y + corner.y * (size / 2.0 + 0.6), z + BARRIER_THICK / 2.0)
		_crystal(at, Vector3(0, 0, 1), 1.2, rng)
	var light := OmniLight3D.new()
	light.light_color = Color(0.5, 0.85, 1.0)
	light.light_energy = 2.0
	light.omni_range = 14.0
	light.position = Vector3(tube.x, tube.y, z + BARRIER_THICK / 2.0 + 2.0)
	_add(light, "Lights/Shortcut")
	_lane(z, gap_x, GATE_PULL)


## Bounce mushrooms spread along the hall, near the middle. Own random
## numbers: halls without them stay as they were.
func _bouncers(seg: Dictionary, z0: float, z1: float) -> void:
	var rng := _deco_rng(31)
	var count := int(seg.bouncers)
	var w: float = seg.width
	for i in count:
		var z := z0 - (z0 - z1) * (i + 0.5) / float(count)
		var x := rng.randf_range(-w / 4.0, w / 4.0)
		var base := LEDGE_Y
		if seg.floor != "ground":
			# A rock column from the depth carries it, a little below the ledges.
			base = BOUNCER_COLUMN_TOP
			var column := Vector3(x, (DEPTH_Y + base) / 2.0, z)
			var size := Vector3(4.0, base - DEPTH_Y, 4.0)
			_collider("rock", column, size, Vector3.ZERO)
			_model("pillar", "rock", Transform3D(Basis.IDENTITY.scaled(size * Vector3(1.3, 1.0, 1.3)), column))
		_bouncer(Vector3(x, base, z))


## One giant mushroom standing at base: stem, a wide glowing cap to land on
## (flat collision on top), the bounce area just above it, a teal light.
func _bouncer(base: Vector3) -> void:
	var stem_height := 3.0
	var radius := 4.0
	var top := base.y + stem_height + 1.0
	_collider("rock", Vector3(base.x, base.y + stem_height / 2.0, base.z), Vector3(1.6, stem_height, 1.6), Vector3.ZERO)
	_collider("rock", Vector3(base.x, top - 0.5, base.z), Vector3(radius * 1.6, 1.0, radius * 1.6), Vector3.ZERO)
	var look := Node3D.new()
	look.position = base
	var stem := MeshInstance3D.new()
	var stem_mesh := CylinderMesh.new()
	stem_mesh.top_radius = 0.7
	stem_mesh.bottom_radius = 1.1
	stem_mesh.height = stem_height + 0.5
	stem_mesh.radial_segments = 8
	stem_mesh.rings = 1
	stem.mesh = stem_mesh
	stem.material_override = MATERIALS.root
	stem.position = Vector3(0, (stem_height + 0.5) / 2.0, 0)
	look.add_child(stem)
	# The cap squashes around its bottom (Bouncer.bounce()).
	var pivot := Node3D.new()
	pivot.position = Vector3(0, stem_height, 0)
	var cap := MeshInstance3D.new()
	var cap_mesh := SphereMesh.new()
	cap_mesh.radius = radius
	cap_mesh.height = 2.6
	cap_mesh.is_hemisphere = true
	cap_mesh.radial_segments = 14
	cap_mesh.rings = 4
	cap.mesh = cap_mesh
	cap.material_override = MATERIALS.cap
	pivot.add_child(cap)
	look.add_child(pivot)
	_limit_range(look, PROP_VISIBLE_RANGE)
	_add(look, "Props/Bouncer")
	var area := Area3D.new()
	area.set_script(BOUNCER)
	area.position = Vector3(base.x, top + 0.7, base.z)
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = radius * 0.8
	cylinder.height = 1.4
	shape.shape = cylinder
	area.add_child(shape)
	area.cap = pivot
	_add(area, "Dynamic/Bouncer")
	var light := OmniLight3D.new()
	light.light_color = Color(0.4, 1.0, 0.8)
	light.light_energy = 1.4
	light.omni_range = 14.0
	light.position = Vector3(base.x, top + 2.0, base.z)
	_add(light, "Lights/Bouncer")


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


## Only collision, rotated, not drawn (the look comes from a model).
## "ice" and "slick" do not hold the hook.
func _collider(material: String, pos: Vector3, size: Vector3, rotation: Vector3) -> void:
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.transform = Transform3D(Basis.from_euler(rotation), pos + Vector3(_shift, 0, 0))
	(_ice_body if material in ["ice", "slick"] else _body).add_child(shape)


## Only drawn: a RockMesh model; the variant follows from the position.
func _model(kind: String, material: String, xform: Transform3D) -> void:
	xform.origin.x += _shift
	var key := "%s|%d|%s" % [kind, RockMesh.variant_at(xform.origin) % RockMesh.VARIANTS, material]
	if not _models.has(key):
		_models[key] = []
	_models[key].append(xform)


## Only drawn, no collision (the rough look of walls and ceiling).
func _shape(material: String, pos: Vector3, size: Vector3, rotation: Vector3) -> void:
	if not _meshes.has(material):
		_meshes[material] = []
	_meshes[material].append(Transform3D(Basis.from_euler(rotation).scaled_local(size), pos + Vector3(_shift, 0, 0)))


## Only collision, axis-aligned, not drawn ("ice" does not hold the hook).
func _solid(material: String, pos: Vector3, size: Vector3) -> void:
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position = pos + Vector3(_shift, 0, 0)
	(_ice_body if material == "ice" else _body).add_child(shape)


func _box_basis(material: String, pos: Vector3, size: Vector3, basis: Basis) -> void:
	pos.x += _shift
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
	_models = {}
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
		instance.visibility_range_end = HALL_VISIBLE_RANGE
		instance.name = "Hall%d_%s" % [_hall, material]
		geometry.add_child(instance)
	for key: String in _models:
		var parts := key.split("|")
		var transforms: Array = _models[key]
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.mesh = RockMesh.get_mesh(parts[0], int(parts[1]))
		multimesh.instance_count = transforms.size()
		for i in transforms.size():
			multimesh.set_instance_transform(i, transforms[i])
		var instance := MultiMeshInstance3D.new()
		instance.multimesh = multimesh
		instance.material_override = MATERIALS[parts[2]]
		instance.visibility_range_end = HALL_VISIBLE_RANGE
		instance.name = "Hall%d_%s_%s_%s" % [_hall, parts[0], parts[1], parts[2]]
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
	if node is Node3D:
		(node as Node3D).position.x += _shift
	parent.add_child(node, true)
