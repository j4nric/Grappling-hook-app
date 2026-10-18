extends "res://tests/test_case.gd"
## New hall mechanics (level "Updraft"): rising air lifts, brittle
## stalactites break and let go of the rope (and grow back on restart),
## speed rings boost, dark halls dim the light and switch on the head lamp.


func run() -> void:
	levels = Levels.LIST
	level_index = level_named("level_06")
	await load_main()
	var p := player()
	var level: Level = main.level
	await wait_frames(5)
	InputRouter.throw_requested.emit(Vector2(0, -300), Vector2(0, -3000))
	await wait_frames(2)
	p.release("tap")

	# Updraft: from a standstill inside the column, the player rises.
	var updraft: Updraft = level.get_node("Dynamic").find_children("Updraft*", "Area3D", false, false)[0]
	_put(p, updraft.global_position + Vector3(0, -5, 0), Vector3.ZERO)
	await wait_frames(30)
	check(p.velocity.y > 5.0, "the updraft lifts the player (%.1f m/s up)" % p.velocity.y)
	check(p.velocity.y <= updraft.max_rise + 0.01, "up to its top speed")

	# Brittle stalactite: holds, cracks, breaks, the rope goes.
	var brittle: Brittle = level.get_node("Dynamic").find_children("Brittle*", "AnimatableBody3D", false, false)[0]
	var reasons: Array[String] = []
	p.rope_released.connect(func(reason: String) -> void: reasons.append(reason))
	_put(p, brittle.global_position + Vector3(0, -42, 0), Vector3.ZERO)
	await wait_frames(1)
	# Hook it where a real throw would: on its surface.
	var query := PhysicsRayQueryParameters3D.create(p.global_position, brittle.global_position)
	query.exclude = [p.get_rid()]
	var hit := p.get_world_3d().direct_space_state.intersect_ray(query)
	check(not hit.is_empty() and hit.collider == brittle, "the brittle stalactite can be hit")
	p.attach(hit.get("position", brittle.global_position), Vector3.DOWN, brittle)
	check(brittle.is_cracking(), "the hooked stalactite cracks")
	await wait_frames(roundi(brittle.hold_time * 60.0) + 5)
	check(brittle.is_broken, "it breaks after %.1f s" % brittle.hold_time)
	check("broke" in reasons, "the rope lets go when it breaks (%s)" % [reasons])
	await wait_frames(30)
	check(brittle.global_position.y < brittle._home.origin.y - 1.0, "the broken stalactite falls")
	main.restart()
	await wait_frames(2)
	check(not brittle.is_broken and brittle.global_position.is_equal_approx(brittle._home.origin), "restart puts it back")

	# Speed ring: passing through fires the player forward.
	var rings: Array[Node] = level.get_node("Dynamic").find_children("Ring*", "Area3D", false, false)
	check(rings.size() == 4, "the ring hall has 4 rings")
	var ring: SpeedRing = rings[0]
	var passed := [0]
	level.ring_passed.connect(func() -> void: passed[0] += 1)
	_put(p, ring.global_position + Vector3(0, 0, 3), Vector3(0, 0, -12))
	await wait_frames(20)
	check(passed[0] == 1, "flying through the ring counts")
	check(-p.velocity.z >= ring.boost_speed - 5.0, "the ring boosts (%.1f m/s forward)" % -p.velocity.z)

	# Dark hall: the light goes down, the head lamp comes on.
	var dark: Array = level.dark_ranges[0]
	check(not level.is_dark_at(0.0) and level.is_dark_at((float(dark[0]) + float(dark[1])) / 2.0), "the dark hall is marked")
	_put(p, Vector3(0, 10, (float(dark[0]) + float(dark[1])) / 2.0), Vector3.ZERO)
	for i in 60:
		p.velocity = Vector3.ZERO
		await get_tree().process_frame
	check(main.darkness > 0.95, "in the dark hall it gets dark (%.2f)" % main.darkness)
	check(p.figure.lamp.visible and p.figure.lamp.light_energy > 2.5, "the head lamp is on")
	check(main.environment.ambient_light_energy < main._base_ambient * 0.5, "the ambient light is dimmed")
	main.restart()
	for i in 60:
		await get_tree().process_frame
	check(main.darkness < 0.05 and not p.figure.lamp.visible, "back at the start it is light again")

	# The generator uses the new hall kinds too.
	var kinds := {}
	for seed_value in range(1, 60):
		for hall in CaveGenerator.segments(seed_value):
			kinds[hall.kind] = true
	for kind in ["updraft", "brittle", "rings", "dark"]:
		check(kinds.has(kind), "the generator builds %s halls" % kind)


func _put(p: CharacterBody3D, at: Vector3, velocity: Vector3) -> void:
	p.release("tap")
	p.global_position = at
	p.velocity = velocity
	p.reset_physics_interpolation()
