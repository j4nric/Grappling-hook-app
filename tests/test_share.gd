extends "res://tests/test_case.gd"
## Sharing: runs as text codes (a friend's run becomes the rival ghost),
## tuning sets A/B/C and pasted tuning values, the curve of finish times.


func run() -> void:
	_run_codes()
	levels = Levels.with_procedural()
	level_index = 0
	await load_main()
	await _rival()
	_tuning_sets()
	await _history()
	main.free()
	# The active tuning set and its values stay after a restart of the game.
	await load_main()
	var tuning := main.get_node("Tuning")
	check(tuning.active_slot() == "B" and is_equal_approx(player().gravity, 50.0), "the active set is kept")


func _run_codes() -> void:
	var positions := PackedVector3Array()
	var anchors := PackedVector3Array()
	for i in 400:
		var t := i * Ghost.SAMPLE_TIME
		positions.append(Vector3(sin(t) * 20.0, 10.0 + cos(t * 1.3) * 6.0, -t * 30.0))
		anchors.append(Ghost.NO_ANCHOR if i % 40 < 15 else Vector3(3.3, 30.12, -float(i / 40) * 60.0))
	# A respawn: a jump far back.
	positions[300] = Vector3(0, 2, -100)
	var code := RunCode.encode("level_07@0a1b2c3d", 19.876, {"positions": positions, "anchors": anchors})
	print("    run code for 20 s: %d characters" % code.length())
	check(code.begins_with("GC1:level_07@0a1b2c3d:19876:"), "the code names level, version and time")
	check(code.length() < 4000, "a 20 s run fits a short message (%d characters)" % code.length())
	var run := RunCode.decode("Beat this! %s see you" % code)
	check(run.get("id") == "level_07@0a1b2c3d" and is_equal_approx(run.get("time", 0.0), 19.876), "the code is found in a message")
	var max_error := 0.0
	var anchors_match := true
	var decoded: Dictionary = run.get("run", {})
	var got_positions: PackedVector3Array = decoded.get("positions", PackedVector3Array())
	var got_anchors: PackedVector3Array = decoded.get("anchors", PackedVector3Array())
	check(got_positions.size() == 400 and got_anchors.size() == 400, "every sample comes back")
	for i in mini(got_positions.size(), 400):
		max_error = maxf(max_error, got_positions[i].distance_to(positions[i]))
		if anchors[i].is_finite() != got_anchors[i].is_finite() \
				or (anchors[i].is_finite() and got_anchors[i].distance_to(anchors[i]) > 0.05):
			anchors_match = false
	check(max_error < 0.05, "positions within 5 cm (%.3f m)" % max_error)
	check(anchors_match, "rope anchors and rope-less samples come back")
	check(RunCode.decode("hello").is_empty() and RunCode.decode("GC1:level_07@0a1b2c3d:100:").is_empty(),
			"text without a valid code is no run")


func _rival() -> void:
	var tutorial := "res://scenes/levels/level_00.tscn"
	var scene: Level = Levels.instantiate(tutorial)
	var tutorial_id := Records.id(tutorial, scene)
	scene.free()
	var start := Vector3(0, 1, -2)
	var positions := PackedVector3Array()
	for i in 200:
		positions.append(start + Vector3(0, 0, -i * 1.5))
	var run := {"positions": positions, "anchors": PackedVector3Array()}
	var message: String = main.load_run_code("from a friend: " + RunCode.encode(tutorial_id, 9.5, run))
	check(message.begins_with("Rival loaded"), "a friend's run loads (%s)" % message)
	check(main.level_list[main.level_index] == tutorial, "its level is loaded")
	var rival: Ghost = main.rival
	check(rival.has_replay(), "the run is the rival ghost")
	rival.update_run(1.0, Vector3.ZERO)
	check(rival.global_position.distance_to(positions[20]) < 0.1, "the rival plays the friend's run")
	check(rival.recording().positions.is_empty(), "the rival records nothing")
	check(main._rival_time() == 9.5, "the rival's time is shown")
	main.free()
	await load_main()
	main.load_level(Levels.LIST.find(tutorial))
	check(main.rival.has_replay(), "the rival stays for the level")

	check(main.load_run_code(RunCode.encode("level_00@deadbeef", 9.0, run)).contains("another version"),
			"a run from another level version is refused")
	check(main.load_run_code(RunCode.encode("level_99@deadbeef", 9.0, run)).contains("does not have"),
			"a run from an unknown level is refused")
	check(main.load_run_code("no code").begins_with("No run code"), "pasted text without a code is refused")
	check(main.share_run().begins_with("Finish the level"), "nothing to share before the first finish")

	# A daily cave of another day takes the place of today's.
	var daily := Levels.cave_path("daily", 20260101)
	var daily_scene := Levels.instantiate(daily)
	var daily_id := Records.id(daily, daily_scene)
	daily_scene.free()
	message = main.load_run_code(RunCode.encode(daily_id, 30.0, run))
	check(message.begins_with("Rival loaded") and main.level_list[main.level_index] == daily, "a run of another daily cave loads it (%s)" % message)

	# Sharing the own best run.
	main.load_level(Levels.LIST.find(tutorial))
	Records.submit(main._record_id, 12.0)
	Records.save_ghost(main._record_id, run)
	main._best = 12.0
	check(main.share_run().begins_with("Run copied"), "the best run is shared")


func _tuning_sets() -> void:
	var tuning := main.get_node("Tuning")
	var values: Dictionary = tuning.parse_values(
			"Grappling Cave tuning:\nPlayer/gravity = 30 (default 43)\nCameraRig/offset:z = 9.5 (default 10.5)")
	check(values == {"Player/gravity": 30.0, "CameraRig/offset:z": 9.5}, "copied values are read back (%s)" % values)
	values = tuning.parse_values("Player throw_speed_per_px 0.03, hook_min_speed 40, gravity 43; " +
			"CameraRig base_fov 61, offset:z 10.5; SpeedLines start_speed 45, Unknown thing 3, Debug shown 1")
	check(values.size() == 7 and values.get("World/SpeedLines/start_speed") == 45.0 and values.get("Player/hook_min_speed") == 40.0,
			"a typed list is read (%s)" % values)

	tuning.apply_values({"Player/gravity": 30.0})
	check(is_equal_approx(player().gravity, 30.0) and tuning.is_tuned(), "pasted values are applied")
	check(tuning.active_slot() == "A", "set A is active at first")
	tuning.switch_slot("B")
	check(is_equal_approx(player().gravity, 30.0), "a new set starts as a copy")
	tuning._sliders["Player/gravity"].value = 50.0
	tuning.switch_slot("A")
	check(is_equal_approx(player().gravity, 30.0), "set A comes back")
	tuning.switch_slot("C")
	tuning._reset()
	tuning.switch_slot("B")
	check(is_equal_approx(player().gravity, 50.0), "set B comes back")
	tuning.switch_slot("C")
	check(not tuning.is_tuned(), "set C stays at the defaults")
	tuning.switch_slot("B")


func _history() -> void:
	for i in 55:
		Stats.add_finish("level_00@0000aaaa", 20.0 - i * 0.1)
	var times := Stats.history("level_00@0000aaaa")
	check(times.size() == Stats.HISTORY_SIZE and is_equal_approx(times[-1], 14.6), "the newest finishes are kept")
	Stats.add_finish("level_00@0000bbbb", 18.0)
	check(Stats.history("level_00@0000bbbb") == [18.0] and Stats.history("level_00@0000aaaa").is_empty(),
			"a new level version starts a new curve")

	# The curve in the stats screen of the real level.
	Stats.add_finish(main._record_id, 13.0)
	Stats.add_finish(main._record_id, 11.0)
	Stats.add(Stats.group(main.level_list[main.level_index]), {"runs": 2, "finishes": 2})
	main.open_menu()
	main.menu._toggle_stats()
	await wait_frames(2)
	var curves: Array[Sparkline] = main.menu.stats_curves()
	check(curves.size() == 1 and curves[0].times == [13.0, 11.0], "the stats show the curve of finish times")
	main.menu.close()
