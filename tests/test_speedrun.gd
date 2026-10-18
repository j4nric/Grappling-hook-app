extends "res://tests/test_case.gd"
## Speedrun loop: start signal, persistent best time, medals, ghost.


func run() -> void:
	await load_main()
	var p := player()
	var path: String = levels[0]
	var best_label: Label = main.get_node("HUD/Safe/BestLabel")
	await wait_frames(5)
	check(best_label.text.begins_with("Gold "), "without a record the HUD shows the gold time")

	InputRouter.throw_requested.emit(Vector2(0, -300), Vector2(0, -3000))
	await get_tree().process_frame
	check(main.go_label.visible, "first throw shows GO!")
	await wait_frames(60)
	p.global_position = Vector3(0, 0, main.level.finish_z())
	await wait_frames(3)
	check(main._finished, "finish reached")
	var time: float = main._elapsed
	check(is_equal_approx(Records.best_time(path), time), "best time is saved (%.2f s)" % time)
	check(main.get_node("HUD/Safe/FinishPanel/Lines/Medal").text == "GOLD", "fast run earns gold")
	check(Records.load_ghost(path).size() > 10, "ghost of the best run is saved")

	# A new session loads the record and replays the ghost.
	main.free()
	await load_main()
	p = player()
	check(is_equal_approx(main._best, time), "best time survives a restart of the game")
	check(main.get_node("HUD/Safe/BestLabel").text.contains("Gold"), "HUD shows best time and medal")
	InputRouter.throw_requested.emit(Vector2(0, -300), Vector2(0, -3000))
	await wait_frames(10)
	check(main.ghost.visible, "ghost runs along")
	check(not Records.submit(path, time + 1.0), "a slower time is no new best")
	check(is_equal_approx(Records.best_time(path), time), "slower time leaves the record")

	# Medal thresholds.
	var level: Level = main.level
	check(Records.medal(level, level.gold_time) == Records.Medal.GOLD, "gold at the gold time")
	check(Records.medal(level, level.silver_time) == Records.Medal.SILVER, "silver at the silver time")
	check(Records.medal(level, level.bronze_time) == Records.Medal.BRONZE, "bronze at the bronze time")
	check(Records.medal(level, level.bronze_time + 1.0) == Records.Medal.NONE, "slower: no medal")

	# The level menu shows the record.
	main.open_menu()
	var first: Button = main.menu._list.get_child(0)
	check(first.text.contains("%.2f" % time), "menu shows the best time")
	main.menu.close()
