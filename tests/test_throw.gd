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
