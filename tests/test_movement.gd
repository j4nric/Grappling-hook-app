extends "res://tests/test_case.gd"
## Impacts and landings keep momentum: ceiling redirect, wall-kick, head-on
## crash, landing slide, and a moving obstacle that crushes.


func run() -> void:
	await load_main()
	var p := player()
	var deflections := [0]
	p.deflected.connect(func(_speed: float) -> void: deflections[0] += 1)

	# Zip into the ceiling at 45°: with deflection on, the speed is turned
	# along the ceiling (the tuned default may switch it off).
	var keep: float = p.deflect_keep
	p.deflect_keep = 1.0
	await _launch(p, Vector3(0, 5, -5), Vector3(0, 30, -30))
	var before := Vector2(30, 30).length()
	await wait_until(func() -> bool: return deflections[0] > 0, 30)
	check(deflections[0] > 0, "ceiling hit is a deflection")
	check(p.velocity.length() >= before * 0.8, "ceiling keeps the speed (%.1f of %.1f m/s)" % [p.velocity.length(), before])
	p.deflect_keep = keep
	check(p.velocity.z < -25.0, "ceiling redirect points forward (%.1f m/s)" % p.velocity.z)
	check(p.velocity.length() <= before + 0.01, "a deflection never adds speed")

	# Glancing hit on a side wall: kicks off it and keeps going forward.
	deflections[0] = 0
	await _launch(p, Vector3(4, 2, -5), Vector3(20, 0, -30))
	await wait_until(func() -> bool: return deflections[0] > 0, 30)
	check(deflections[0] > 0, "side wall hit is a deflection")
	check(p.velocity.x < -1.0, "wall-kick bounces off the wall (x %.1f m/s)" % p.velocity.x)
	check(p.velocity.y > 0.0, "wall-kick lifts (y %.1f m/s)" % p.velocity.y)
	check(p.velocity.z < -25.0, "wall-kick keeps the forward speed (%.1f m/s)" % p.velocity.z)

	# Head-on into the back wall: no bounce back.
	deflections[0] = 0
	await _launch(p, Vector3(0, 2, 5), Vector3(0, 3, 30))
	await wait_until(func() -> bool: return deflections[0] > 0, 30)
	await wait_frames(1)
	check(p.velocity.z > -1.0, "head-on crash does not bounce back (z %.1f m/s)" % p.velocity.z)

	# Landing with forward speed rolls on instead of stopping; with light
	# slide braking it slides on for a while.
	var slide: float = p.slide_friction
	p.slide_friction = 6.0
	var landed := [false]
	p.landed.connect(func(_speed: float) -> void: landed[0] = true)
	await _launch(p, Vector3(0, -1, -5), Vector3(0, -15, -10))
	await wait_until(func() -> bool: return landed[0], 60)
	var flat := Vector2(p.velocity.x, p.velocity.z).length()
	check(flat > 10.0, "landing rolls forward (%.1f m/s)" % flat)
	await wait_frames(30)
	flat = Vector2(p.velocity.x, p.velocity.z).length()
	check(flat > 5.0, "the slide keeps going for a while (%.1f m/s)" % flat)
	p.slide_friction = slide
	await wait_frames(150)
	check(p.velocity.length() < 0.5, "the slide stops (%.1f m/s)" % p.velocity.length())

	# A block coming down onto the grounded player crushes: back to the start.
	main.restart()
	await wait_frames(20)
	check(p.is_on_floor(), "player stands for the crush test")
	var crushed := [false]
	p.crushed.connect(func() -> void: crushed[0] = true)
	var stomper := AnimatableBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(4, 1, 4)
	shape.shape = box
	stomper.add_child(shape)
	var start := p.global_position
	p.global_position = start + Vector3(0, 0, -6)
	stomper.position = p.global_position + Vector3(0, 2.0, 0)
	main.level.add_child(stomper)
	for i in 60:
		stomper.global_position.y -= 0.05
		await get_tree().physics_frame
		if crushed[0]:
			break
	check(crushed[0], "a block pressing down crushes the player")
	check(p.global_position.distance_to(start) < 1.0, "crushed: back to the checkpoint")
	stomper.queue_free()


## Puts the player in the air at offset from the start, moving.
func _launch(p: CharacterBody3D, offset: Vector3, velocity: Vector3) -> void:
	main.restart()
	await wait_frames(2)
	p.global_position = main.level.start_position() + offset
	p.reset_physics_interpolation()
	p.velocity = velocity
