extends "res://tests/test_case.gd"
## Hook throw, flight, pull and release, driven through InputRouter signals.


func run() -> void:
	await load_main()
	var p := player()
	await wait_frames(30)
	check(p.is_on_floor(), "player rests on the floor at start")

	# Strong throw straight up: sticks to the ceiling ahead and pulls.
	InputRouter.throw_requested.emit(Vector2(0, -300), Vector2(0, -3000))
	check(p.hook_state == p.HookState.FLYING, "hook flies after a throw")
	var stuck := await wait_until(func() -> bool: return p.hook_state == p.HookState.ATTACHED, 60)
	check(stuck, "strong throw sticks within 1 s")
	check(p.anchor.y > 4.5, "anchor is on the ceiling (y=%.1f)" % p.anchor.y)
	check(p.anchor.z < -2.0, "anchor is ahead (z=%.1f)" % p.anchor.z)
	var start_z := p.global_position.z
	await wait_until(func() -> bool: return p.hook_state == p.HookState.IDLE, 180)
	check(p.hook_state == p.HookState.IDLE, "rope lets go at the end of the pull")
	check(p.global_position.z < start_z - 3.0, "pull moved the player forward")

	# Weak throw falls short and must not stick to the floor.
	main.restart()
	await wait_frames(30)
	InputRouter.throw_requested.emit(Vector2(0, -300), Vector2.ZERO)
	await wait_frames(120)
	check(p.hook_state != p.HookState.ATTACHED, "weak throw does not stick to the floor")

	# Downward swipes are ignored.
	main.restart()
	await wait_frames(5)
	InputRouter.throw_requested.emit(Vector2(0, 300), Vector2(0, 3000))
	check(p.hook_state == p.HookState.IDLE, "downward swipe throws nothing")

	# Sideways swipe throws toward the right wall.
	InputRouter.throw_requested.emit(Vector2(300, -100), Vector2(3000, -1000))
	await wait_until(func() -> bool: return p.hook_state == p.HookState.ATTACHED, 60)
	check(p.anchor.x > 2.0, "sideways swipe aims right (x=%.1f)" % p.anchor.x)

	# Pitch assist: right under the ceiling the throw goes flatter, so it
	# still reaches far; from the floor it keeps its pitch.
	main.restart()
	await wait_frames(10)
	# The test tunnel is low (ceiling 9 m): a reach that fits it.
	var reach: float = p.min_throw_reach
	p.min_throw_reach = 14.0
	var up := Vector2(0, -300)
	var normal_dir: Vector3 = p._throw_direction(up, 60.0)
	check(is_equal_approx(rad_to_deg(asin(normal_dir.y)), p.throw_pitch), "from the floor the throw keeps its pitch")
	p.global_position = main.level.start_position() + Vector3(0, 10, -10)
	p.reset_physics_interpolation()
	var flat_dir: Vector3 = p._throw_direction(up, 60.0)
	check(flat_dir.y < normal_dir.y - 0.1, "under the ceiling the throw is flatter (%.0f deg)" % rad_to_deg(asin(flat_dir.y)))
	var path: Dictionary = p.predict_hook_path(flat_dir, 60.0)
	var points: PackedVector3Array = path.points
	check(path.hit and p.global_position.distance_to(points[-1]) >= p.min_throw_reach, "the flatter throw holds further away")
	p.min_throw_reach = reach
