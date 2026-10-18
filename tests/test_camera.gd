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
	await wait_frames(10)
	check(rig._roll > 3.0, "moving right banks the view (%.1f deg)" % rig._roll)
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
