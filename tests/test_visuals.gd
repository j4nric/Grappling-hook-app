extends "res://tests/test_case.gd"
## Visual plumbing: pixel view camera, lights per level, rope tube, effects.


func run() -> void:
	await load_main()
	var p := player()
	await wait_frames(5)

	var rig := main.get_node("CameraRig")
	var view: Camera3D = main.get_node("World/PixelView/SubViewport/ViewCamera")
	check(view.global_transform.is_equal_approx(rig.camera.global_transform), "pixel view camera follows the rig")
	check(main.get_node("World/PixelView").stretch_shrink >= 2, "world renders at reduced resolution")

	for i in Levels.LIST.size():
		var level: Node = load(Levels.LIST[i]).instantiate()
		var lights := level.find_children("*", "OmniLight3D", true, false).size()
		check(lights >= 5, "level %d has torches (%d lights)" % [i + 1, lights])
		level.free()

	InputRouter.throw_requested.emit(Vector2(0, -300), Vector2(0, -3000))
	await wait_until(func() -> bool: return p.hook_state == p.HookState.ATTACHED, 60)
	await get_tree().process_frame
	var effects := main.get_node("Effects")
	check(effects._sparks.emitting, "sparks fly where the hook bites")
	var rope_mesh: ImmediateMesh = p.rope.mesh
	check(rope_mesh.get_surface_count() == 1, "rope is drawn")
	var vertices: PackedVector3Array = rope_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	check(vertices.size() >= 24, "rope is a tube, visible in the pixel view")
	await wait_until(func() -> bool: return p.velocity.length() > effects.trail_speed, 120)
	await get_tree().physics_frame
	check(effects._trail.emitting, "speed trail shows at high speed")
