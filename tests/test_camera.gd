extends "res://tests/test_case.gd"
## Camera: horizontal FOV, look toward the anchor, roll, shake.


func run() -> void:
	await load_main()
	var rig := main.get_node("CameraRig")
	var cam: Camera3D = rig.camera
	var p := player()
	await wait_frames(30)
	check(cam.keep_aspect == Camera3D.KEEP_WIDTH, "FOV is horizontal for portrait")
	check(absf(cam.fov - rig.base_fov) < 1.0, "resting FOV is the base FOV")

	# The hook sticks: shake, and the view turns toward the anchor.
	var look_before: Vector3 = rig._look_target
	InputRouter.throw_requested.emit(Vector2(0, -300), Vector2(0, -3000))
	await wait_until(func() -> bool: return p.hook_state == p.HookState.ATTACHED, 60)
	await get_tree().physics_frame
	check(rig._trauma > 0.0, "hook sticking shakes the camera")
	await wait_frames(8)
	check(rig._look_target.y > look_before.y + 0.3, "view turns toward the anchor above")
	check(cam.fov > rig.base_fov + 1.0, "speed widens the FOV")

	# Sideways speed rolls the view.
	main.restart()
	await wait_frames(5)
	p.velocity = Vector3(15, 0, 0)
	await wait_frames(30)
	var lean := minf(15.0 * rig.roll_per_speed, rig.max_roll)
	check(rig._roll > lean * 0.6, "moving right banks the view (%.1f of %.1f deg)" % [rig._roll, lean])
	check(rig._roll <= rig.max_roll + 0.01, "roll stays within its limit")

	# Backed up against the back wall (z = 10): the camera stays in front of
	# it instead of showing the rock from behind.
	main.restart()
	p.global_position = main.level.start_position() + Vector3(0, 0, 8.5)
	p.reset_physics_interpolation()
	await wait_frames(30)
	check(rig.global_position.z < 10.0, "camera stays in front of the back wall (z %.1f)" % rig.global_position.z)
	p.global_position = main.level.start_position() + Vector3(0, 0, -20)
	p.reset_physics_interpolation()
	await wait_frames(90)
	check(absf(rig.global_position.z - (p.global_position.z + rig.offset.z)) < 0.5, "camera backs out to its offset again")

	# Under the ceiling the camera drops and looks up (tunnel ceiling: y = 9).
	main.restart()
	await wait_frames(2)
	p.global_position = Vector3(0, 7.5, -30)
	p.reset_physics_interpolation()
	for i in 90:
		p.velocity = Vector3.ZERO
		await get_tree().process_frame
	check(rig.ceiling_factor > 0.6, "right under the ceiling the framing changes (%.2f)" % rig.ceiling_factor)
	check(rig.global_position.y < p.global_position.y + rig.offset.y - 1.0, "the camera drops below its normal height")
	check(rig._look_target.y > p.global_position.y + rig.look_ahead.y + 1.0, "and looks up into the hall")
	main.restart()
	for i in 90:
		await get_tree().process_frame
	check(rig.ceiling_factor < 0.2, "with space above, normal framing (%.2f)" % rig.ceiling_factor)

	# Finish shot: slow motion, the camera circles; restart ends it.
	InputRouter.throw_requested.emit(Vector2(0, -300), Vector2(0, -3000))
	await wait_frames(10)
	p.global_position = Vector3(0, 0, main.level.finish_z())
	await wait_frames(3)
	check(main._finished and rig.orbiting, "the finish starts the orbit shot")
	check(Engine.time_scale < 0.5, "in slow motion (%.2f)" % Engine.time_scale)
	for i in 120:
		await get_tree().process_frame
	check(is_equal_approx(Engine.time_scale, 1.0), "the slow motion ends")
	main.restart()
	check(not rig.orbiting, "restart ends the orbit")

	# Respawn: the picture fades back in from black.
	var fade: ColorRect = main.get_node("World/Fade")
	await wait_frames(20)
	main._on_killed()
	check(fade.color.a > 0.9, "a respawn starts black")
	await wait_frames(40)
	check(fade.color.a < 0.05, "and fades back in")
