extends "res://tests/test_case.gd"
## The cave builder: same seed, same cave; every level has its parts; hall
## transitions are slanted; gates are ice with an open slit; nothing to stand
## on above the ceiling blocks.


func run() -> void:
	levels = Levels.LIST
	var segments := [{"length": 40.0, "floor": "ground"}, {"length": 60.0, "ceiling": 20.0, "width": 30.0,
			"gate": [4.0, 12.0], "checkpoint": true, "islands": 2, "pillars": 1}]
	var a := _built(segments, 7)
	var b := _built(segments, 7)
	var c := _built(segments, 8)
	check(_signature(a) == _signature(b), "same seed builds the same cave")
	check(_signature(a) != _signature(c), "another seed builds another cave")
	for level in [a, b, c]:
		level.free()

	await load_main()
	for i in Levels.LIST.size():
		main.load_level(i)
		await wait_frames(30)
		var level: Level = main.level
		var p := player()
		check(p.is_on_floor() and p.global_position.distance_to(level.start_position()) < 1.0,
				"level %d: the player stands on the start ledge" % (i + 1))
		check(level.finish_z() < -150.0, "level %d is long enough (%.0f m)" % [i + 1, -level.finish_z()])
		check(level.get_node("Checkpoints").get_child_count() >= 1, "level %d has a checkpoint" % (i + 1))
		check(level.find_children("*", "OmniLight3D", true, false).size() >= 8, "level %d is lit" % (i + 1))
		check(level.get_node("Props").get_child_count() >= 8, "level %d has crystals and light shafts" % (i + 1))
		# Falling from the start ledge into the depth is caught.
		check(level.kill_y > -60.0 and level.kill_y < -10.0, "level %d catches falls" % (i + 1))

	var space: PhysicsDirectSpaceState3D = main.get_world_3d().direct_space_state
	# Level 1: hall 3 (ceiling 30 m) leads into the lower hall 4 (24 m) at
	# z = -175 over a slanted slab.
	main.load_level(0)
	await wait_frames(2)
	var hit := _ray(space, Vector3(0, 20, -165), Vector3(0, 40, -165))
	check(not hit.is_empty() and hit.normal.z > 0.2, "a lower hall starts with a slanted ceiling (normal %s)" % [hit.get("normal")])

	# Level 5: the first gate (hall 2, x = -8, 14 m wide, z = -75) is ice with
	# an open slit.
	main.load_level(4)
	await wait_frames(2)
	var through := _ray(space, Vector3(-8, 15, -60), Vector3(-8, 15, -80))
	check(through.is_empty() or through.position.z < -76.0, "the gate slit is open")
	var wall := _ray(space, Vector3(12, 15, -60), Vector3(12, 15, -80))
	check(not wall.is_empty() and wall.collider.is_in_group("no_hook"), "the gate wall is ice")

	# No standing on top of ceiling blocks: straight up from the middle of a
	# hall, the first thing above the ceiling is solid lid all the way.
	var up := _ray(space, Vector3(0, 0, -100), Vector3(0, 80, -100))
	check(not up.is_empty(), "the ceiling closes the hall")
	if not up.is_empty():
		var beyond := _ray(space, up.position + Vector3(0, 6, 0), up.position + Vector3(0, 7, 0))
		var inside: Array = space.intersect_point(_point(up.position + Vector3(0, 6, 0)))
		check(not inside.is_empty() or not beyond.is_empty(), "above the ceiling is solid rock")


func _built(segments: Array, seed_value: int) -> Level:
	var level := Level.new()
	level.segments = segments
	level.layout_seed = seed_value
	level.build()
	return level


func _signature(level: Level) -> String:
	var parts := []
	for shape: CollisionShape3D in level.get_node("Geometry").find_children("*", "CollisionShape3D", true, false):
		parts.append(str(shape.transform.origin.snapped(Vector3.ONE * 0.01)))
	return ",".join(parts)


func _ray(space: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [player().get_rid()]
	return space.intersect_ray(query)


func _point(at: Vector3) -> PhysicsPointQueryParameters3D:
	var query := PhysicsPointQueryParameters3D.new()
	query.position = at
	return query
