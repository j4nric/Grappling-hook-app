extends "res://tests/test_case.gd"
## Smooth drawing: physics interpolation on, visuals follow the interpolated
## player every rendered frame, teleports do not interpolate.


func run() -> void:
	check(ProjectSettings.get_setting("physics/common/physics_interpolation"), "physics interpolation is on")
	await load_main()
	var p := player()
	var rig := main.get_node("CameraRig")
	await wait_frames(5)
	check(rig.physics_interpolation_mode == Node.PHYSICS_INTERPOLATION_MODE_OFF, "camera rig moves itself per frame")
	check(p.rope.physics_interpolation_mode == Node.PHYSICS_INTERPOLATION_MODE_OFF, "rope is placed per frame")

	InputRouter.throw_requested.emit(Vector2(0, -300), Vector2(0, -3000))
	await wait_frames(4)
	await get_tree().process_frame
	var origin: Vector3 = p.get_global_transform_interpolated().origin + p.HOOK_OFFSET
	var vertices: PackedVector3Array = p.rope.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var nearest := INF
	for v in vertices:
		nearest = minf(nearest, v.distance_to(origin))
	check(nearest < 0.1, "rope starts at the interpolated hand (%.3f m)" % nearest)

	# Teleport (restart): the camera target is the new position at once.
	p.global_position = Vector3(0, 0, -100)
	await wait_frames(2)
	main.restart()
	await get_tree().process_frame
	var drawn := p.get_global_transform_interpolated().origin
	check(drawn.distance_to(p.global_position) < 0.01, "a teleport is not interpolated")
