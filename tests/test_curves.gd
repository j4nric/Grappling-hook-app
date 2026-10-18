extends "res://tests/test_case.gd"
## Winding caves: a shifted hall is the same hall, moved sideways; the walls
## between shifted halls close up; a shortcut barrier has the wide way round
## at one side and a tube straight through; lanes guide the test bot.


func run() -> void:
	# The same cave with every hall shifted 20 m: every piece moves 20 m.
	var plain := _layout([{"template": "slalom", "bouncers": 1, "checkpoint": true}], 0.0)
	var moved := _layout([{"template": "slalom", "bouncers": 1, "checkpoint": true}], 20.0)
	check(plain.size() == moved.size() and plain.size() > 30, "same pieces (%d / %d)" % [plain.size(), moved.size()])
	var off := 0
	for i in mini(plain.size(), moved.size()):
		if not (plain[i] + Vector3(20, 0, 0)).is_equal_approx(moved[i]):
			off += 1
	check(off == 0, "a shifted hall is the same hall, 20 m to the side (%d pieces off)" % off)

	levels = Levels.LIST
	level_index = level_named("level_09")
	await load_main()
	var level: Level = main.level
	var space: PhysicsDirectSpaceState3D = main.get_world_3d().direct_space_state
	await wait_frames(2)
	check(level.level_name == "Winding Rift", "the winding level is in the list")
	# Find the barrier: the hall with a shortcut.
	var z0 := 0.0
	var barrier_hall := {}
	var barrier_z := 0.0
	for raw: Dictionary in level.segments:
		var hall := CavernBuilder.full_segment(raw)
		if float(hall.shortcut) > 0.0:
			barrier_hall = hall
			barrier_z = z0 - float(hall.length) * 0.55
		z0 -= float(hall.length)
	check(not barrier_hall.is_empty(), "Winding Rift has a shortcut")
	if not barrier_hall.is_empty():
		var sx: float = barrier_hall.shift
		var w: float = barrier_hall.width
		var size: float = barrier_hall.shortcut
		var tube := Vector3(sx - w * 0.08 * _gap_side(level, barrier_z, sx, w), float(barrier_hall.ceiling) * 0.5, 0)
		var through := _ray(space, Vector3(tube.x, tube.y, barrier_z + 12.0), Vector3(tube.x, tube.y, barrier_z - 12.0))
		check(through.is_empty(), "the tube goes straight through")
		var blocked := _ray(space, Vector3(tube.x, tube.y + size, barrier_z + 12.0), Vector3(tube.x, tube.y + size, barrier_z - 12.0))
		check(not blocked.is_empty(), "rock around the tube")
		var lane: Array = level.lane_ahead(barrier_z + 20.0, 30.0)
		check(not lane.is_empty(), "a lane leads the bot round the barrier")
		if not lane.is_empty():
			var gap_x: float = lane[0]
			var round := _ray(space, Vector3(gap_x, 5.0, barrier_z + 12.0), Vector3(gap_x, 5.0, barrier_z - 12.0))
			check(round.is_empty(), "the way round at the side is open")
	# Shifted halls are guided to their middle.
	var shifted := CavernBuilder.full_segment(level.segments[1])
	var guide: Array = level.lane_ahead(-1.0, 80.0)
	check(not guide.is_empty() and is_equal_approx(float(guide[0]), float(shifted.shift)), "the bot is led to the middle of a shifted hall")
	# Editor sliders.
	check("shift" in CaveEditor.KEYS and "shortcut" in CaveEditor.KEYS, "the cave editor shifts halls and adds shortcuts")


## Origins of every collision shape and drawn piece of a one-hall cave whose
## halls all sit `shift` m to the side, in build order.
func _layout(halls: Array, shift: float) -> Array[Vector3]:
	var level := Level.new()
	var shifted := []
	for raw: Dictionary in halls:
		var hall := raw.duplicate()
		hall.shift = shift
		shifted.append(hall)
	level.segments = shifted
	add_child(level)
	var origins: Array[Vector3] = []
	for n in level.find_children("*", "", true, false):
		# (Drawn pieces sit in MultiMeshes, which headless runs cannot read back;
		# every rock has its collision box, though.)
		if n is Node3D and n.get_parent() != level and n.get_parent().name != "Geometry":
			# (Not the group nodes, hall bodies and meshes: they stay at the origin.)
			origins.append(n.global_position)
	remove_child(level)
	level.free()
	# Model meshes are grouped by variant (which follows the position): sort.
	origins.sort_custom(func(a: Vector3, b: Vector3) -> bool: return a.z < b.z or (a.z == b.z and (a.y < b.y or (a.y == b.y and a.x < b.x))))
	return origins


## +1 when the way round is on the right (the tube then sits left of the middle).
func _gap_side(level: Level, z: float, sx: float, _w: float) -> float:
	var lane: Array = level.lane_ahead(z + 1.0, 5.0)
	return 1.0 if lane.is_empty() or float(lane[0]) > sx else -1.0


func _ray(space: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [player().get_rid()]
	return space.intersect_ray(query)
