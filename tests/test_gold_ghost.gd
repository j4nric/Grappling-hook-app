extends "res://tests/test_case.gd"
## Gold ghosts: every level ships a bot run for its current version; the gold
## ghost plays it so it reaches the finish exactly at the gold time; the
## pause menu switches it; edited caves have none.


func run() -> void:
	for path in Levels.LIST:
		var level: Level = Levels.instantiate(path)
		var gold := GoldGhosts.load_for(path, level)
		check(not gold.is_empty(), "%s has a gold ghost for this version (re-record: RECORD_GHOSTS=1 BOT_FULL=1 TEST_FILTER=test_levels)" % level.level_name)
		level.free()
	# Another version of a level gets no ghost.
	var changed: Level = Levels.instantiate(Levels.LIST[1])
	changed.layout_seed += 1
	check(GoldGhosts.load_for(Levels.LIST[1], changed).is_empty(), "a changed level shows no old gold ghost")
	changed.free()

	levels = Levels.LIST
	level_index = level_named("level_01")
	await load_main()
	var ghost: Ghost = main.gold_ghost
	var level: Level = main.level
	check(ghost.has_replay(), "the gold ghost is loaded")
	# At the gold time it is at the end of its run, at the finish.
	ghost.update_run(level.gold_time, Vector3.ZERO)
	check(ghost.visible and ghost.global_position.z < level.finish_z() + 3.0,
			"at the gold time the gold ghost is at the finish (z %.1f, finish %.1f)" % [ghost.global_position.z, level.finish_z()])
	ghost.update_run(level.gold_time * 0.5, Vector3.ZERO)
	check(ghost.global_position.z > level.finish_z() + 10.0, "halfway it is still on the way")
	check(ghost.recording().positions.is_empty(), "it records nothing")
	# The switch in the pause menu.
	main.pause_menu._on_gold_toggle()
	ghost.update_run(1.0, Vector3.ZERO)
	check(not ghost.visible and not Settings.gold_ghost_enabled, "the pause menu switches it off")
	main.pause_menu._on_gold_toggle()
	check(Settings.gold_ghost_enabled, "and on again")
