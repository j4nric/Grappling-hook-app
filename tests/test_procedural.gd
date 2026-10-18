extends "res://tests/test_case.gd"
## Procedural caves: seeded and fair; daily and random entries in the menu;
## the bot finishes several seeds within bronze (prints time vs estimate).

const Bot := preload("res://tests/bot.gd")
const SEEDS := [11, 2024, 31337, 48213]
const MAX_FRAMES := 60 * 75


func run() -> void:
	check(CaveGenerator.segments(5) == CaveGenerator.segments(5), "same seed, same cave")
	check(CaveGenerator.segments(5) != CaveGenerator.segments(6), "another seed, another cave")
	for seed_value in range(1, 40):
		var halls := CaveGenerator.segments(seed_value)
		var middle := halls.size() - 2
		var fair: bool = CavernBuilder.full_segment(halls[0]).floor == "ground" and CavernBuilder.full_segment(halls[-1]).floor == "ground" and middle >= 4 and middle <= 6
		for i in range(1, halls.size() - 1):
			if i > 1 and halls[i].kind == halls[i - 1].kind:
				fair = false
		if halls[1].kind == "gate":
			fair = false
		check(fair, "seed %d gives a fair run of halls" % seed_value)
	var cave := CaveGenerator.make("random", 77)
	check(cave.level_name == "Cave #77", "random caves are named by their seed")
	check(cave.gold_time < cave.silver_time and cave.silver_time < cave.bronze_time, "medal times are ordered")
	cave.free()
	check(str(CaveGenerator.daily_seed()).length() == 8, "the daily seed is the date")
	check(Records.key(Levels.cave_path("daily", 20261018)) == "daily_20261018", "records per daily cave")

	# Menu: authored levels, today's cave, a random cave (new each time).
	levels = Levels.with_procedural()
	await load_main()
	check(main.level_list.size() == Levels.LIST.size() + 2, "menu lists the daily and the random cave")
	var random_index: int = main.level_list.size() - 1
	main.open_menu()
	main.menu._choose(random_index)
	await wait_frames(2)
	var first: String = main.level_list[random_index]
	check(main.level is Level and main.level.has_node("Finish"), "the random cave is built")
	main.restart()
	check(main.level_list[random_index] == first, "restart keeps the cave")
	main.open_menu()
	main.menu._choose(random_index)
	await wait_frames(2)
	check(main.level_list[random_index] != first, "choosing it again makes a new cave")
	main._on_next()
	await wait_frames(2)
	check(main.level_index == random_index and main.level_list[random_index] != first, "New cave after the finish")

	# The bot gets through several seeds.
	for seed_value in SEEDS:
		var single: Array[String] = [Levels.cave_path("random", seed_value)]
		main.level_list = single
		var best := INF
		for delay in [0, 7, 13, 19]:
			if best <= main.level.bronze_time and not Bot.full_runs():
				break
			main.load_level(0)
			Bot.reset([0, 7, 13, 19].find(delay))
			await wait_frames(2 + delay)
			var p := player()
			var frames := 0
			while not main._finished and frames < MAX_FRAMES:
				Bot.step(p)
				await get_tree().physics_frame
				frames += 1
			if main._finished:
				best = minf(best, main._elapsed)
		var estimate := CaveGenerator.estimate_time(main.level.segments)
		print("    seed %d: bot %.2f s, estimate %.1f s, bronze %.1f s" % [seed_value, best, estimate, main.level.bronze_time])
		check(best <= main.level.bronze_time, "bot gets bronze in cave %d" % seed_value)
