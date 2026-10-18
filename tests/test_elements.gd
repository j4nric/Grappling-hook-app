extends "res://tests/test_case.gd"
## Level elements: checkpoints with lava and fall respawn, ice that does not
## hold the hook, anchors that ride on moving obstacles, the level menu.


func run() -> void:
	levels = Levels.LIST
	level_index = 1  # Lava Deep: lava below halls 2-4, checkpoint at hall 3
	await load_main()
	var p := player()
	await wait_frames(5)
	var checkpoint: Area3D = main.level.get_node("Checkpoints").get_child(0)
	var respawn: Vector3 = checkpoint.get_node("Respawn").global_position
	var lava: Area3D = main.level.get_node("KillZones").get_child(0)
	InputRouter.throw_requested.emit(Vector2(0, -300), Vector2(0, -3000))
	p.release("tap")
	p.global_position = respawn
	await wait_frames(3)
	p.global_position = lava.global_position
	await wait_frames(3)
	check(p.global_position.distance_to(respawn) < 1.0, "lava sends the player back to the checkpoint (%s)" % p.global_position)
	check(main._running, "the timer keeps running after lava")
	# Falling into the depth does the same.
	p.global_position = Vector3(0, main.level.kill_y - 1.0, respawn.z - 20.0)
	await wait_frames(2)
	check(p.global_position.distance_to(respawn) < 1.0, "a fall into the depth goes back to the checkpoint")
	InputRouter.restart_requested.emit()
	await wait_frames(2)
	check(absf(p.global_position.z) < 1.0, "restart goes back to the level start")

	# Ice (no_hook) does not hold the hook, rock does: Ice Ceiling.
	main.load_level(2)
	await wait_frames(5)
	var ice: Array[Node] = main.level.get_node("Geometry").find_children("Ice*", "StaticBody3D", false, false)
	check(not ice.is_empty(), "the ice level has ice")
	if not ice.is_empty():
		check(ice[0].is_in_group("no_hook"), "ice is in the no_hook group")
		check(not p.can_stick({"collider": ice[0], "normal": Vector3.DOWN}), "ice ceiling does not hold the hook")
	var rock: StaticBody3D = main.level.get_node("Geometry/Hall1")
	check(p.can_stick({"collider": rock, "normal": Vector3.DOWN}), "rock ceiling holds the hook")
	check(not p.can_stick({"collider": rock, "normal": Vector3.UP}), "floors do not hold the hook")

	# Movers: the anchor rides along.
	main.load_level(3)
	await wait_frames(5)
	var mover: Node3D = main.level.get_node("Movers").get_child(0)
	p.global_position = mover.global_position + Vector3(0, -6, 6)
	p.velocity = Vector3.ZERO
	p.attach(mover.global_position + Vector3(0, -3, 1), Vector3.BACK, mover)
	var before: Vector3 = p.anchor
	await wait_frames(5)
	check(p.anchor.distance_to(before) > 0.01, "anchor on a mover moves with it (%.2f m)" % p.anchor.distance_to(before))

	# Level menu lists every level and starts the chosen one.
	main.open_menu()
	check(get_tree().paused, "menu pauses the game")
	main.menu._choose(4)
	await wait_frames(2)
	check(not get_tree().paused and main.level_index == 4, "menu starts the chosen level")
