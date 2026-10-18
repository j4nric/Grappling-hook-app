extends "res://tests/test_case.gd"
## Every level loads, has its parts, and the bot reaches the finish in time
## (at least bronze). Prints the bot times to help set medal times.

const Bot := preload("res://tests/bot.gd")
## Physics frames the bot gets per level (60 per second).
const MAX_FRAMES := 60 * 60
## Frames to wait before the bot starts, one run each (with its own lean,
## see Bot.reset()): the best of them judges the level.
const START_DELAYS := [0, 5, 11, 17, 23]


func run() -> void:
	for i in Levels.LIST.size():
		levels = Levels.LIST
		level_index = i
		if main:
			main.free()
		await load_main()
		var level: Level = main.level
		check(level.has_node("Start") and level.has_node("Finish"), "level %d has start and finish" % (i + 1))
		check(level.gold_time < level.silver_time and level.silver_time < level.bronze_time, "level %d medal times are ordered" % (i + 1))
		var medals := [level.gold_time, level.silver_time, level.bronze_time]
		var level_name := level.level_name
		# The bot's flight is chaotic: tiny differences in the start change
		# the run. The best of a few starts judges the level, not one throw.
		var best := INF
		var best_deaths := 0
		var best_run := {}
		var times: Array[String] = []
		for delay in START_DELAYS:
			if best <= float(medals[2]) and not Bot.full_runs():
				break
			var result := await bot_run(Levels.LIST, i, START_DELAYS.find(delay), delay, MAX_FRAMES)
			times.append("%.2f" % result.time if result.finished else "-")
			if result.time < best:
				best = result.time
				best_deaths = result.deaths
				best_run = result.recording
		print("    level %d %-12s bot best %.2f s, %d deaths (medals %.1f/%.1f/%.1f) runs %s" % [i + 1, level_name, best, best_deaths, medals[0], medals[1], medals[2], " ".join(times)])
		if OS.get_environment("RECORD_GHOSTS") == "1" and best < INF:
			# The best run becomes the level's gold ghost.
			var scene: Level = Levels.instantiate(Levels.LIST[i])
			GoldGhosts.save(Levels.LIST[i], scene, best, best_run)
			scene.free()
		check(best < INF, "bot finishes level %d" % (i + 1))
		check(best <= float(medals[2]), "bot gets at least bronze in level %d" % (i + 1))

	# The same start gives the same time, whatever ran before (each run in a
	# fresh main scene): medal times can be measured again any time.
	var again := level_named("level_09")
	var one := await bot_run(Levels.LIST, again, 1, START_DELAYS[1], MAX_FRAMES)
	var two := await bot_run(Levels.LIST, again, 1, START_DELAYS[1], MAX_FRAMES)
	check(one.finished and is_equal_approx(one.time, two.time),
			"bot runs are reproducible (%.2f s, again %.2f s)" % [one.time, two.time])
	levels = Levels.LIST
	main.free()
	await load_main()

	# Changing level right at the finish line must not finish the next level
	# (levels 3 and 4 share the finish position).
	main.load_level(2)
	await wait_frames(2)
	InputRouter.throw_requested.emit(Vector2(0, -300), Vector2(0, -3000))
	player().global_position = Vector3(0, 0, main.level.finish_z())
	await wait_frames(3)
	check(main._finished, "teleport onto the finish line finishes level 3")
	main.load_level(3)
	await wait_frames(5)
	check(not main._finished, "the next level does not start finished")
