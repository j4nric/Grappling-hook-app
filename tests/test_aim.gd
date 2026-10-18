extends "res://tests/test_case.gd"
## Aim preview, aim assist, slow motion while aiming, hook retract after a miss.


func run() -> void:
	await load_main()
	var p := player()
	await wait_frames(30)

	# The preview arc ends where a throw at aim_preview_speed sticks.
	InputRouter.aim_changed.emit(Vector2(0, -300))
	check(p.aim_line.visible and p.aim_marker.visible, "aiming shows arc and target marker")
	var predicted: Vector3 = p.aim_marker.global_position
	var flick := Vector2(0, -p.aim_preview_speed / p.throw_speed_per_px)
	InputRouter.throw_requested.emit(Vector2(0, -300), flick)
	check(not p.aim_line.visible, "throwing hides the preview")
	await wait_until(func() -> bool: return p.hook_state == p.HookState.ATTACHED, 60)
	check(p.anchor.distance_to(predicted) < 1.0, "hook sticks where the preview said (%.2f m off)" % p.anchor.distance_to(predicted))
	check(is_equal_approx(p.last_throw_speed, p.aim_preview_speed), "last throw speed is recorded")

	# Aim assist bends a throw that would find nothing toward a surface.
	main.restart()
	await wait_frames(5)
	var flat := Vector3(0, 0, -1)
	check(not p._sticks_along(flat), "flat throw down the tunnel finds nothing")
	check(p._assisted_direction(flat) == flat, "assist off keeps the direction")
	p.aim_assist_angle = 20.0
	var assisted: Vector3 = p._assisted_direction(flat)
	check(p._sticks_along(assisted), "assist finds a surface")
	check(rad_to_deg(assisted.angle_to(flat)) <= 20.5, "assist stays inside its cone")
	p.aim_assist_angle = 0.0

	# Slow motion while aiming; the run timer keeps real time.
	p.aim_time_scale = 0.5
	InputRouter.throw_requested.emit(Vector2(0, -300), Vector2(0, -3000))
	var start: float = main._elapsed
	InputRouter.aim_changed.emit(Vector2(0, -300))
	check(is_equal_approx(Engine.time_scale, 0.5), "aiming slows the game down")
	for i in 60:
		await get_tree().process_frame
	var elapsed: float = main._elapsed - start
	check(absf(elapsed - 1.0) < 0.1, "timer counts real time in slow motion (%.2f s)" % elapsed)
	InputRouter.aim_cancelled.emit()
	check(is_equal_approx(Engine.time_scale, 1.0), "cancelling the aim restores the speed")
	p.aim_time_scale = 1.0

	# A miss flies back visibly, then disappears.
	main.restart()
	await wait_frames(30)
	var missed := [false]
	p.hook_missed.connect(func() -> void: missed[0] = true)
	InputRouter.throw_requested.emit(Vector2(0, -300), Vector2.ZERO)
	await wait_until(func() -> bool: return missed[0], 120)
	check(missed[0], "weak throw is reported as a miss")
	await get_tree().process_frame
	check(p.flight_hook.visible, "hook is still visible while it flies back")
	await wait_frames(int(p.hook_retract_time * 60) + 3)
	check(not p.flight_hook.visible and not p.flight_rope.visible, "hook is gone after flying back")
