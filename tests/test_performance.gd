extends "res://tests/test_case.gd"
## Performance guards: only the nearest lights are on, far props and halls are
## not drawn, caves build fast.

const MAX_BUILD_MS := 60.0


func run() -> void:
	levels = Levels.with_procedural()
	for path in levels:
		var start := Time.get_ticks_usec()
		var level := Levels.instantiate(path)
		level.build()
		var ms := (Time.get_ticks_usec() - start) / 1000.0
		check(ms < MAX_BUILD_MS, "%s builds in %.1f ms" % [path.get_file(), ms])
		var props := level.get_node("Props").find_children("*", "GeometryInstance3D", true, false)
		var limited := props.filter(func(g: GeometryInstance3D) -> bool: return g.visibility_range_end > 0.0)
		check(limited.size() == props.size(), "%s: every prop has a draw distance" % path.get_file())
		var halls := level.get_node("Geometry").find_children("*", "MultiMeshInstance3D", false, false)
		check(halls.all(func(h: MultiMeshInstance3D) -> bool: return h.visibility_range_end > 0.0), "%s: halls have a draw distance" % path.get_file())
		level.free()

	# Light LOD in the busiest level (Gates: ~38 lights).
	level_index = level_named("level_05")
	await load_main()
	var lod: LightLod = main.get_node("LightLod")
	await wait_frames(30)
	var total: int = main.level.find_children("*", "Light3D", true, false).size()
	check(total > lod.max_lights, "the level has more lights than the limit (%d)" % total)
	check(lod.active_count() <= lod.max_lights, "at most %d lights are on (%d of %d)" % [lod.max_lights, lod.active_count(), total])
	var start_light := _nearest_light(main.level.start_position())
	check(start_light.visible, "the light next to the start is on")
	var far_light := _farthest_light(main.level.start_position())
	check(not far_light.visible, "the farthest light is off")
	# Moving on switches lights: the far one comes on, the start one goes.
	player().global_position = far_light.global_position + Vector3(0, -2, 6)
	player().reset_physics_interpolation()
	await wait_frames(90)
	check(far_light.visible, "lights ahead come on as the player gets there")
	check(not start_light.visible or start_light.global_position.distance_to(far_light.global_position) < lod.max_distance, "lights behind go off")
	check(lod.active_count() <= lod.max_lights, "still at most %d lights on" % lod.max_lights)


func _nearest_light(at: Vector3) -> Light3D:
	var lights: Array[Node] = main.level.find_children("*", "Light3D", true, false)
	lights.sort_custom(func(a: Node, b: Node) -> bool: return (a as Light3D).global_position.distance_to(at) < (b as Light3D).global_position.distance_to(at))
	return lights[0]


func _farthest_light(at: Vector3) -> Light3D:
	var lights: Array[Node] = main.level.find_children("*", "Light3D", true, false)
	lights.sort_custom(func(a: Node, b: Node) -> bool: return (a as Light3D).global_position.distance_to(at) > (b as Light3D).global_position.distance_to(at))
	return lights[0]
