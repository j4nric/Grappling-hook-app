extends "res://tests/test_case.gd"
## Open ceiling: no rock to hook above, only a far vault that does not hold;
## floating stones in a lane hold the hook (and bob, the anchor rides along);
## slick walls do not hold. Plus the new look: rock models and decoration.


func run() -> void:
	levels = ["res://tests/levels/open_01.tscn"]
	await load_main()
	var p := player()
	var level: Level = main.level
	var space := p.get_world_3d().direct_space_state
	await wait_frames(5)

	# Hall 2 runs from z = -40 to -138; its ceiling height is 26.
	var up := _ray(space, Vector3(0, 20, -60), Vector3(0, 26 + CavernBuilder.OPEN_HEIGHT + 4, -60))
	check(not up.is_empty() and up.position.y > 26 + CavernBuilder.OPEN_HEIGHT - 1.0, "no ceiling above an open hall (hit at %.1f m)" % up.get("position", Vector3.ZERO).y)
	check(not up.is_empty() and up.collider.is_in_group("no_hook"), "the far vault does not hold the hook")
	var wall := _ray(space, Vector3(20, 10, -80), Vector3(40, 10, -80))
	check(not wall.is_empty() and wall.collider.is_in_group("no_hook"), "slick walls do not hold the hook")

	var floaters := level.get_tree().get_nodes_in_group("floater")
	check(floaters.size() >= 6 and floaters.size() <= 7, "a floating stone every 14 m (%d)" % floaters.size())
	var first: Floater = null
	for f: Floater in floaters:
		if first == null or f.global_position.z > first.global_position.z:
			first = f
	check(first.global_position.y > 18.0 and first.global_position.y < 26.0, "stones float a little below the ceiling height")

	# Hook the first stone from below: it holds, and the anchor rides along.
	p.global_position = first.global_position + Vector3(0, -14, 8)
	p.velocity = Vector3.ZERO
	p.reset_physics_interpolation()
	await wait_frames(1)
	var hit := _ray(space, p.global_position, first.global_position)
	check(not hit.is_empty() and hit.collider == first, "the stone can be hit")
	p.attach(hit.get("position", first.global_position), hit.get("normal", Vector3.DOWN), hit.get("collider"))
	check(p.hook_state == p.HookState.ATTACHED, "the hook holds on a floating stone")
	var offset: Vector3 = p.anchor - first.global_position
	await wait_frames(20)
	check((p.anchor - first.global_position).distance_to(offset) < 0.05, "the anchor rides along with the bobbing stone")
	check(absf(first.position.y - first._base.y) > 0.01 or absf(first.position.y - first._base.y) <= first.bob, "the stone bobs")

	# The new look: rock models and decoration are built.
	var geometry := level.get_node("Geometry")
	var models := geometry.find_children("*boulder*", "MultiMeshInstance3D", false, false)
	check(not models.is_empty(), "rock models are drawn (boulders)")
	check(not level.get_node("Props").find_children("Mushrooms*", "Node3D", false, false).is_empty(), "mushrooms grow on the floors")
	check(not level.get_node("Props").find_children("Beacon*", "Node3D", false, false).is_empty(), "beacons mark the exits")
	var floater_mesh: MeshInstance3D = first.find_children("*", "MeshInstance3D", false, false)[0]
	check(floater_mesh.mesh is ArrayMesh and floater_mesh.mesh.get_surface_count() == 1, "floating stones are rock models")

	# The real levels: stalactites drawn as cones, wide halls lit down the middle.
	main.level_list = Levels.LIST
	main.load_level(level_named("level_07"))
	await wait_frames(2)
	geometry = main.level.get_node("Geometry")
	check(not geometry.find_children("*stalactite*", "MultiMeshInstance3D", false, false).is_empty(), "stalactites are drawn as cones")
	var ceiling_crystals := 0
	for crystal in main.level.get_node("Props").find_children("Crystal*", "Node3D", false, false):
		if crystal.global_position.y > 20.0:
			ceiling_crystals += 1
	check(ceiling_crystals >= 6, "wide halls have crystals along the ceiling (%d)" % ceiling_crystals)


func _ray(space: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [player().get_rid()]
	return space.intersect_ray(query)
