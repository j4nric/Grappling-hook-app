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
	levels = Levels.LIST
	await load_main()
	for i in Levels.LIST.size():
		main.load_level(i)
		Bot.reset()
		await wait_frames(2)
		var level: Level = main.level
		check(level.has_node("Start") and level.has_node("Finish"), "level %d has start and finish" % (i + 1))
		check(level.gold_time < level.silver_time and level.silver_time < level.bronze_time, "level %d medal times are ordered" % (i + 1))
		# The bot's flight is chaotic: tiny differences in the start change
		# the run. The best of a few starts judges the level, not one throw.
		var best := INF
		var best_deaths := 0
		for delay in START_DELAYS:
			main.load_level(i)
			Bot.reset(START_DELAYS.find(delay))
			await wait_frames(2 + delay)
			var p := player()
			var deaths := [0]
			main.level.killed.connect(func() -> void: deaths[0] += 1)
			var frames := 0
			while not main._finished and frames < MAX_FRAMES:
				Bot.step(p)
				await get_tree().physics_frame
				frames += 1
			if main._finished and main._elapsed < best:
				best = main._elapsed
				best_deaths = deaths[0]
		level = main.level
		print("    level %d %-12s bot best %.2f s, %d deaths (medals %.1f/%.1f/%.1f)" % [i + 1, level.level_name, best, best_deaths, level.gold_time, level.silver_time, level.bronze_time])
		check(best < INF, "bot finishes level %d" % (i + 1))
		check(best <= level.bronze_time, "bot gets at least bronze in level %d" % (i + 1))

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
