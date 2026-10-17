extends "res://tests/test_case.gd"
## Level elements: checkpoints with lava respawn, ice that does not hold the
## hook, anchors that ride on moving obstacles, the level menu.


func run() -> void:
	level_index = 1  # Lava Gaps: checkpoint at z=-102, lava at z -30..-50
	await load_main()
	var p := player()
	await wait_frames(5)
	InputRouter.throw_requested.emit(Vector2(0, -300), Vector2(0, -3000))
	p.release("tap")
	p.global_position = Vector3(0, 0, -102)
	await wait_frames(3)
	p.global_position = Vector3(0, -7, -40)
	await wait_frames(3)
	check(absf(p.global_position.z + 102.0) < 1.0, "lava sends the player back to the checkpoint (z=%.1f)" % p.global_position.z)
	check(main._running, "the timer keeps running after lava")
	InputRouter.restart_requested.emit()
	await wait_frames(2)
	check(absf(p.global_position.z) < 1.0, "restart goes back to the level start")

	# Ice (no_hook) does not hold the hook: Ice Ceiling, ceiling ice at z -35..-60.
	main.load_level(2)
	await wait_frames(5)
	p.global_position = Vector3(0, -3.6, -40)
	p.velocity = Vector3.ZERO
	await wait_frames(2)
	var missed := [false]
	p.hook_missed.connect(func() -> void: missed[0] = true)
	InputRouter.throw_requested.emit(Vector2(0, -300), Vector2(0, -3000))
	await wait_until(func() -> bool: return p.hook_state != p.HookState.FLYING, 60)
	check(missed[0] and p.hook_state == p.HookState.IDLE, "ice ceiling does not hold the hook")

	# Movers: the anchor rides along.
	main.load_level(3)
	await wait_frames(5)
	var mover: Node3D = main.level.get_node("Movers/Mover0")
	p.global_position = mover.global_position + Vector3(0, -6, 6)
	p.velocity = Vector3.ZERO
	p.attach(mover.global_position + Vector3(0, -3, 1), Vector3.BACK, mover)
	var before: Vector3 = p.anchor
	await wait_frames(5)
	check(p.hook_state != p.HookState.ATTACHED or p.anchor.distance_to(before) > 0.01, "anchor on a mover moves with it")
	check(p.anchor.distance_to(before) > 0.01, "anchor moved (%.2f m)" % p.anchor.distance_to(before))

	# Level menu lists every level and starts the chosen one.
	main.open_menu()
	check(get_tree().paused, "menu pauses the game")
	main.menu._choose(4)
	await wait_frames(2)
	check(not get_tree().paused and main.level_index == 4, "menu starts the chosen level")
