extends "res://tests/test_case.gd"
## The climber figure: the rope arm reaches for the anchor, legs trail at
## speed, zip launches flip, landings crouch, the scarf trails behind, the
## rope sags while the hook flies and is straight when it pulls.


func run() -> void:
	await load_main()
	var p := player()
	var figure: PlayerFigure = p.figure
	await wait_frames(10)
	check(figure.hand_r != null and figure.leg_l != null and figure.scarf != null, "the figure has its joints and scarf")
	var standing_feet := figure.knee_r.global_position.y
	check(standing_feet < p.global_position.y - 0.3, "standing: knees below the hips")

	# Hook in flight: the rope sags; the rope arm reaches for the hook.
	InputRouter.throw_requested.emit(Vector2(0, -300), Vector2(0, -3000))
	await wait_frames(6)
	check(p.is_hook_flying(), "a hook flies")
	check(p._flight_visual.sag() > 0.05, "the flying hook's rope sags (%.2f m)" % p._flight_visual.sag())
	check(await wait_until(func() -> bool: return p.hook_state == p.HookState.ATTACHED, 90), "the hook bites")
	for i in 8:
		await get_tree().process_frame
	var arm_dir: Vector3 = (figure.elbow_r.global_position - figure.arm_r.global_position).normalized()
	var to_anchor: Vector3 = (p.anchor - figure.arm_r.global_position).normalized()
	check(rad_to_deg(arm_dir.angle_to(to_anchor)) < 25.0, "the rope arm points at the anchor (%.0f deg)" % rad_to_deg(arm_dir.angle_to(to_anchor)))
	check(p._rope_visual.sag() < 0.3, "the pulling rope is nearly straight (%.2f m)" % p._rope_visual.sag())
	check(p._rope_visual.points[0].distance_to(figure.hand_position()) < 0.05, "the rope starts in the hand")

	# Fast flight: legs trail behind, the scarf streams back.
	main.restart()
	await wait_frames(2)
	p.global_position = main.level.start_position() + Vector3(0, 5, -20)
	p.reset_physics_interpolation()
	for i in 30:
		p.velocity = Vector3(0, 0, -35)
		await get_tree().process_frame
	var knee: Vector3 = figure.knee_r.global_position
	check(knee.z > figure.global_position.z + 0.1, "at speed the legs trail behind (knee z %.2f vs %.2f)" % [knee.z, figure.global_position.z])
	var scarf_end: Vector3 = figure.scarf.points[-1]
	check(scarf_end.z > figure.scarf.points[0].z + 0.3, "the scarf streams behind (%.2f m)" % (scarf_end.z - figure.scarf.points[0].z))

	# Zip launch: a somersault; landing: a crouch.
	p.rope_released.emit("zip")
	check(figure.flip < 1.0, "a zip launch starts the somersault")
	for i in 40:
		await get_tree().process_frame
	check(figure.flip >= 1.0, "the somersault ends")
	p.landed.emit(20.0)
	for i in 3:
		await get_tree().process_frame
	check(figure.hips.position.y < -0.1, "a hard landing crouches")
