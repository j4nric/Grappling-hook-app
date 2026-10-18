extends "res://tests/test_case.gd"
## Pull, zip launch, floor friction and blocked ropes.

var _reasons: Array[String] = []


func run() -> void:
	await load_main()
	var p := player()
	p.rope_released.connect(func(reason: String) -> void: _reasons.append(reason))
	await wait_frames(30)

	# Zip launch: the rope lets go before the ceiling, at full speed.
	InputRouter.throw_requested.emit(Vector2(0, -300), Vector2(0, -3000))
	await wait_until(func() -> bool: return p.hook_state == p.HookState.ATTACHED, 60)
	var anchor: Vector3 = p.anchor
	await wait_until(func() -> bool: return p.hook_state == p.HookState.IDLE, 180)
	check(_reasons.back() == "zip", "pull ends with a zip launch (%s)" % str(_reasons))
	check(p.velocity.length() > 15.0, "zip launch keeps the speed (%.1f m/s)" % p.velocity.length())
	check(p.global_position.distance_to(anchor) <= p.zip_release_distance + 0.5, "zip launch happens close to the anchor")

	# The pull builds up: faster at the end than at the start.
	main.restart()
	await wait_frames(30)
	InputRouter.throw_requested.emit(Vector2(0, -300), Vector2(0, -3000))
	await wait_until(func() -> bool: return p.hook_state == p.HookState.ATTACHED, 60)
	await wait_frames(3)
	var early := p.velocity.length()
	await wait_frames(20)
	check(p.velocity.length() > early, "pull accelerates (%.1f -> %.1f m/s)" % [early, p.velocity.length()])

	# Floor friction: sliding on the floor stops.
	main.restart()
	await wait_frames(30)
	# Above slide_speed it slides on (lighter braking), then stops.
	p.velocity = Vector3(0, 0, -15)
	await wait_frames(120)
	check(p.is_on_floor(), "player is on the floor")
	check(p.velocity.length() < 0.5, "floor friction stops the slide (%.1f m/s)" % p.velocity.length())

	# Rope through an obstacle lets go: HangingBlock1 hangs at z=-40.
	main.restart()
	await wait_frames(5)
	p.global_position = Vector3(0, -2, -34)
	p.velocity = Vector3.ZERO
	p.attach(Vector3(0, 4.99, -46), Vector3.DOWN)
	await wait_frames(int(p.contact_release_grace * 60) + 3)
	check(p.hook_state == p.HookState.IDLE and _reasons.back() == "blocked", "rope through an obstacle lets go (%s)" % str(_reasons))

	# Touching a wall lets go even before the zip distance.
	main.restart()
	await wait_frames(5)
	p.zip_release_distance = 0.0
	InputRouter.throw_requested.emit(Vector2(300, -60), Vector2(3000, -600))
	await wait_until(func() -> bool: return p.hook_state == p.HookState.ATTACHED, 60)
	await wait_until(func() -> bool: return p.hook_state == p.HookState.IDLE, 180)
	check(_reasons.back() == "contact", "touching the wall lets go (%s)" % str(_reasons))
