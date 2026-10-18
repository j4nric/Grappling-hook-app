extends "res://tests/test_case.gd"
## Juice: hit-stop (not counted by the timer), rope twang, zip FOV kick, speed
## lines, wind streaks, flow counter and the speed-dependent wind pitch.


func run() -> void:
	await load_main()
	var p := player()
	var fx := main.get_node("Effects")
	var rig := main.get_node("CameraRig")
	var lines := main.get_node("World/SpeedLines")
	var sfx := main.get_node("Sfx")
	await wait_frames(10)

	# Hit-stop: a fast hook bite nearly freezes the game for a moment.
	InputRouter.throw_requested.emit(Vector2(0, -300), Vector2(0, -3000))
	await wait_frames(1)
	main.restart()
	main._running = true
	p.global_position = main.level.start_position() + Vector3(0, 3, -4)
	p.velocity = Vector3(0, 0, -25)
	p.attach(p.global_position + Vector3(0, 4, -8), Vector3.DOWN)
	check(Engine.time_scale < 0.2, "hit-stop slows the game (%.2f)" % Engine.time_scale)
	check(p._rope_visual.is_plucked(), "the rope twangs when the hook bites")
	# The frame that was already under way runs at full speed.
	await get_tree().process_frame
	await get_tree().process_frame
	var before: float = main._elapsed
	await get_tree().process_frame
	check(Engine.time_scale < 0.2, "hit-stop lasts several frames")
	check(main._elapsed - before < 0.005, "the timer does not count the hit-stop (%.4f s)" % (main._elapsed - before))
	for i in 10:
		await get_tree().process_frame
	check(is_equal_approx(Engine.time_scale, 1.0), "hit-stop ends (%.2f)" % Engine.time_scale)
	await wait_frames(40)
	check(not p._rope_visual.is_plucked(), "the twang dies down")

	# A calm hook (slow player) does not freeze.
	main.restart()
	p.attach(p.global_position + Vector3(0, 6, -8), Vector3.DOWN)
	check(is_equal_approx(Engine.time_scale, 1.0), "no hit-stop for a slow hook")
	main.restart()

	# Zip launch: the FOV kicks out for a moment.
	await wait_frames(30)
	var fov: float = rig.camera.fov
	p.rope_released.emit("zip")
	await get_tree().process_frame
	await get_tree().process_frame
	check(rig.camera.fov > fov + 5.0, "zip launch kicks the FOV (%.1f -> %.1f)" % [fov, rig.camera.fov])
	await wait_frames(90)
	check(rig.camera.fov < rig.base_fov + 3.0, "the FOV kick fades (%.1f)" % rig.camera.fov)

	# Speed lines and wind streaks at high speed, none at rest.
	check(not lines.visible, "no speed lines at rest")
	for i in 30:
		p.velocity = Vector3(0, 0, -50)
		await get_tree().process_frame
	check(lines.visible and lines.intensity > 0.5, "speed lines at full speed (%.2f)" % lines.intensity)
	check(fx._streaks.emitting, "wind streaks at full speed")
	check(sfx._wind.pitch_scale > 1.1, "wind sounds higher at speed (%.2f)" % sfx._wind.pitch_scale)
	main.restart()
	await wait_frames(60)
	check(not lines.visible, "speed lines fade at rest")
	check(not fx._streaks.emitting, "no wind streaks at rest")

	# Flow: hooks in a row without touching the floor.
	var flow_label: Label = main.get_node("HUD/Safe/FlowLabel")
	main._running = true
	p.global_position = main.level.start_position() + Vector3(0, 4, -4)
	p.velocity = Vector3.ZERO
	await wait_frames(1)
	for i in 3:
		p.attach(p.global_position + Vector3(0, 3, -6), Vector3.DOWN)
	check(main.flow == 3, "three hooks in the air: flow 3 (%d)" % main.flow)
	check(flow_label.visible and flow_label.text == "x3", "flow counter shows x3")
	check(main.best_flow == 3, "best flow of the run is kept")
	p.release("tap")
	await wait_until(func() -> bool: return p.is_on_floor(), 120)
	await wait_frames(2)
	check(main.flow == 0 and not flow_label.visible, "landing ends the flow")
	check(main.best_flow == 3, "best flow survives the landing")
	main.restart()
	check(main.best_flow == 0, "restart clears the best flow")
