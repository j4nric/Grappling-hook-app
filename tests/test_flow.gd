extends "res://tests/test_case.gd"
## Cave flow: ceiling and walls are flat to fly and slide along (the rough
## rock is only drawn), and a slide along the ceiling of the Wide Cave keeps
## its speed instead of catching on an edge.


func run() -> void:
	levels = Levels.LIST
	await load_main()
	var space: PhysicsDirectSpaceState3D = main.get_world_3d().direct_space_state
	for i in Levels.LIST.size():
		main.load_level(i)
		await wait_frames(2)
		var level: Level = main.level
		var bumps := 0
		var rays := 0
		var z := 0.0
		for raw: Dictionary in level.segments:
			var seg := CavernBuilder.new()._segment(raw)
			var c: float = seg.ceiling
			var w: float = seg.width
			for k in 12:
				var pz: float = z - float(seg.length) * (k + 0.5) / 12.0
				for px in [-w * 0.35, -w * 0.1, w * 0.15, w * 0.4]:
					var up := _ray(space, Vector3(px, c - 3.0, pz), Vector3(px, c + 3.0, pz))
					if up.is_empty():
						continue
					rays += 1
					# Lower down hangs an obstacle (stalactite), a slanted face is
					# the ramp into the next hall, a steep one a pillar.
					if up.position.y > c - 1.0 and absf(up.normal.z) < 0.1 and absf(up.normal.x) < 0.3 \
							and (absf(up.position.y - c) > 0.01 or up.normal.y > -0.9999):
						bumps += 1
				for side in [-1.0, 1.0]:
					var out := _ray(space, Vector3(side * (w / 2.0 - 3.0), c * 0.5, pz), Vector3(side * (w / 2.0 + 3.0), c * 0.5, pz))
					if out.is_empty():
						continue
					rays += 1
					if absf(out.position.x) > w / 2.0 - 1.0 and absf(out.normal.z) < 0.1 and absf(out.normal.y) < 0.3 \
							and (absf(absf(out.position.x) - w / 2.0) > 0.01 or absf(out.normal.x) < 0.9999):
						bumps += 1
			z -= float(seg.length)
		check(rays > 100 and bumps == 0, "%s: ceiling and walls are flat (%d bumps in %d rays)" % [level.level_name, bumps, rays])

	# No way out of the cave: where a hall gets wider or higher, the frame
	# around the smaller opening is closed (seen from the bigger hall),
	# beside the smaller hall's walls (8 m thick) and above its lid.
	var caves: Array[String] = Levels.LIST.duplicate()
	for seed_value in [11, 2024, 31337, 48213]:
		caves.append(Levels.cave_path("random", seed_value))
	main.level_list = caves
	for i in caves.size():
		main.load_level(i)
		await wait_frames(2)
		var halls: Array = main.level.segments
		var z := 0.0
		for k in range(1, halls.size()):
			var prev := CavernBuilder.full_segment(halls[k - 1])
			var next := CavernBuilder.full_segment(halls[k])
			z -= float(prev.length)
			var gap := (float(next.width) - float(prev.width)) / 2.0
			if gap > 10.0:
				var x := float(prev.width) / 2.0 + 8.0 + (gap - 8.0) / 2.0
				var back := _ray(space, Vector3(x, 10.0, z - 6.0), Vector3(x, 10.0, z + 30.0))
				check(not back.is_empty() and back.position.z < z + 6.0,
						"%s: closed beside hall %d's entrance" % [main.level.level_name, k + 1])
			var prev_top := float(prev.ceiling) + (CavernBuilder.OPEN_HEIGHT if prev.open else 0.0)
			var next_top := float(next.ceiling) + (CavernBuilder.OPEN_HEIGHT if next.open else 0.0)
			if next_top - prev_top > 16.0:
				var y := prev_top + 14.0 + (next_top - prev_top - 14.0) / 2.0
				var over := _ray(space, Vector3(0.0, y, z - 6.0), Vector3(0.0, y, z + 30.0))
				check(not over.is_empty() and over.position.z < z + 6.0,
						"%s: closed above hall %d's entrance" % [main.level.level_name, k + 1])
	main.level_list = Levels.LIST

	# Sliding along the ceiling of the Wide Cave: the speed carries on.
	main.load_level(level_named("level_07"))
	await wait_frames(2)
	var p := player()
	var c: float = CavernBuilder.full_segment(main.level.segments[1]).ceiling
	var lane := INF
	for x in [0.0, -6.0, 6.0, -12.0, 12.0, -18.0, 18.0, -24.0, 24.0]:
		if _ray(space, Vector3(x, c - 1.0, -45.0), Vector3(x, c - 1.0, -115.0)).is_empty() \
				and _ray(space, Vector3(x, c - 2.0, -45.0), Vector3(x, c - 2.0, -115.0)).is_empty():
			lane = x
			break
	check(lane < INF, "the Wide Cave has a free lane under the ceiling")
	if lane < INF:
		p.global_position = Vector3(lane, c - 1.2, -45.0)
		p.reset_physics_interpolation()
		p.velocity = Vector3(0, 6, -35)
		await wait_frames(60)
		check(p.global_position.z < -70.0 and -p.velocity.z > 25.0,
				"sliding along the ceiling keeps the speed (z %.0f, %.1f m/s)" % [p.global_position.z, -p.velocity.z])

	# Fewer obstacles: no stalactite reaches deeper than STALACTITE_MAX (plus
	# the guaranteed hook targets in icy halls).
	check(CavernBuilder.STALACTITE_MAX <= 8.0, "stalactites stay short")


func _ray(space: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [player().get_rid()]
	return space.intersect_ray(query)
