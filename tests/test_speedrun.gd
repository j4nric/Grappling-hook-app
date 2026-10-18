extends "res://tests/test_case.gd"
## Speedrun loop: start signal, persistent best time, medals, ghost, records
## per level version, split times, ghost delta, TUNE* marking, pause menu.


func run() -> void:
	await load_main()
	var p := player()
	var path: String = levels[0]
	var record_id := Records.id(path, main.level)
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
	check(is_equal_approx(Records.best_time(record_id), time), "best time is saved (%.2f s)" % time)
	check(main.get_node("HUD/Safe/FinishPanel/Lines/Medal").text == "GOLD", "fast run earns gold")
	check(Records.load_ghost(record_id).size() > 10, "ghost of the best run is saved")

	# A new session loads the record and replays the ghost.
	main.free()
	await load_main()
	p = player()
	check(is_equal_approx(main._best, time), "best time survives a restart of the game")
	check(main.get_node("HUD/Safe/BestLabel").text.contains("Gold"), "HUD shows best time and medal")
	InputRouter.throw_requested.emit(Vector2(0, -300), Vector2(0, -3000))
	await wait_frames(10)
	check(main.ghost.visible, "ghost runs along")
	check(not Records.submit(record_id, time + 1.0), "a slower time is no new best")
	check(is_equal_approx(Records.best_time(record_id), time), "slower time leaves the record")

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

	# Records belong to one version of a level: a changed layout starts fresh.
	var changed: Level = Levels.instantiate(path)
	check(Records.id(path, changed) == record_id, "same level, same record id")
	changed.segments = [{"length": 10.0}]
	check(Records.id(path, changed) != record_id, "a changed level gets a new record id")
	check(Records.best_time(Records.id(path, changed)) == INF, "the changed level has no record yet")
	changed.free()

	# Split times at checkpoints (tunnel 2: checkpoint at z=-102, finish at -240).
	main.load_level(1)
	await wait_frames(3)
	var split_label: Label = main.get_node("HUD/Safe/SplitLabel")
	var ghost_label: Label = main.get_node("HUD/Safe/GhostLabel")
	await _run_to_finish(p, 40)
	var first_run: float = main._elapsed
	var id_2 := Records.id(levels[1], main.level)
	check(Records.best_splits(id_2).size() == 1, "the best run keeps its split time")
	check(not split_label.visible, "no split without an earlier best")
	main.restart()
	await wait_frames(2)
	InputRouter.throw_requested.emit(Vector2(0, -300), Vector2(0, -3000))
	await wait_frames(20)
	p.global_position = Vector3(0, -3, -60)
	await wait_frames(3)
	check(ghost_label.visible and ghost_label.text.begins_with("ghost "), "the ghost delta shows during the run (%s)" % ghost_label.text)
	p.global_position = Vector3(0, -3, -102)
	await wait_frames(3)
	check(split_label.visible and split_label.text.begins_with("-"), "an earlier checkpoint shows a green split (%s)" % split_label.text)
	check(split_label.get_theme_color("font_color").g > 0.8, "the faster split is green")
	main.restart()

	# TUNE*: a record made with changed tuning values is marked.
	var tuning := main.get_node("Tuning")
	var slider: HSlider = tuning._sliders[tuning._key(tuning.PARAMS[0])]
	slider.value = slider.max_value
	check(tuning.is_tuned(), "a changed slider counts as tuned")
	await wait_frames(2)
	await _run_to_finish(p, 10)
	check(main._elapsed < first_run, "the tuned run is a new best")
	check(Records.is_tuned(id_2), "the record is marked as tuned")
	check(main.get_node("HUD/Safe/FinishPanel/Lines/Best").text.contains("TUNE*"), "the finish screen says TUNE*")
	var best_now: Label = main.get_node("HUD/Safe/BestLabel")
	check(best_now.text.contains("*"), "the HUD marks the tuned best (%s)" % best_now.text)
	slider.value = tuning._defaults[tuning._key(tuning.PARAMS[0])]
	main.restart()

	# Pause menu: medal targets, ghost and sound switches (saved).
	var pause := main.get_node("PauseMenu")
	pause.open()
	check(pause._info.text.contains("Gold %.2f" % main.level.gold_time), "pause menu shows the medal targets")
	pause._on_ghost_toggle()
	pause._on_sound_toggle()
	check(not Settings.ghost_enabled and pause._ghost_toggle.text == "Ghost: off", "ghost can be switched off")
	check(AudioServer.is_bus_mute(0), "sound can be switched off")
	Settings.ghost_enabled = true
	Settings.sound_enabled = true
	Settings.load_settings()
	check(not Settings.ghost_enabled and not Settings.sound_enabled, "the switches are saved")
	pause._on_ghost_toggle()
	pause._on_sound_toggle()
	pause.close()
	check(Settings.ghost_enabled and not AudioServer.is_bus_mute(0), "switched back on")


## Starts a run, waits `frames`, then teleports to the checkpoint and the finish.
func _run_to_finish(p: CharacterBody3D, frames: int) -> void:
	InputRouter.throw_requested.emit(Vector2(0, -300), Vector2(0, -3000))
	await wait_frames(frames)
	if main.level.has_node("Checkpoints"):
		p.global_position = Vector3(0, -3, -102)
		await wait_frames(frames)
	p.global_position = Vector3(0, 0, main.level.finish_z())
	await wait_frames(3)
