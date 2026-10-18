extends "res://tests/test_case.gd"
## Save data stays small (old level versions and old caves are dropped), the
## daily cave follows the UTC date, the level menu scrolls, and the tap that
## picks a level never throws or starts the timer.


func run() -> void:
	# A newer version of a level replaces the older record and its ghost.
	Records.submit("level_01@aaaa0000", 20.0)
	Records.save_ghost("level_01@aaaa0000", {"positions": PackedVector3Array([Vector3.ZERO, Vector3.ONE])})
	Records.submit("level_01@bbbb1111", 25.0)
	check(Records.best_time("level_01@aaaa0000") == INF, "the old version's record is gone")
	check(Records.load_ghost("level_01@aaaa0000").is_empty(), "the old version's ghost is gone")
	check(Records.best_time("level_01@bbbb1111") == 25.0, "the new version's record stays")
	Records.submit("level_02@cccc2222", 30.0)
	check(Records.best_time("level_01@bbbb1111") == 25.0, "other levels are not touched")

	# Only the newest random caves stay.
	for i in Records.KEEP_RANDOM + 5:
		Records.submit("random_%d@ffff0000" % (10000 + i), 40.0)
	var kept := 0
	for i in Records.KEEP_RANDOM + 5:
		if Records.best_time("random_%d@ffff0000" % (10000 + i)) < INF:
			kept += 1
	check(kept == Records.KEEP_RANDOM, "only %d random caves are kept (%d)" % [Records.KEEP_RANDOM, kept])
	check(Records.best_time("random_%d@ffff0000" % (10000 + Records.KEEP_RANDOM + 4)) < INF, "the newest random cave is kept")
	check(Records.best_time("random_10000@ffff0000") == INF, "the oldest random cave is dropped")

	# Daily cave: the UTC date.
	var utc := Time.get_date_dict_from_system(true)
	check(CaveGenerator.daily_seed() == int(utc.year) * 10000 + int(utc.month) * 100 + int(utc.day), "the daily seed is the UTC date")

	# The level menu scrolls when the list is longer than the screen.
	levels = Levels.with_procedural()
	await load_main()
	main.open_menu()
	await wait_frames(2)
	var scroll: ScrollContainer = main.menu._scroll
	check(scroll != null and main.menu._list.get_child_count() == levels.size(), "the menu lists every level in a scroll list")
	check(scroll.size.y <= get_tree().root.get_visible_rect().size.y, "the list fits on the screen")

	# Tapping a level button: the level starts, no throw, no running timer.
	var throws := [0]
	InputRouter.throw_requested.connect(func(_s: Vector2, _f: Vector2) -> void: throws[0] += 1)
	var button: Button = main.menu._list.get_child(1)
	var center := button.get_global_rect().get_center()
	touch(7, center, true)
	await get_tree().process_frame
	touch(7, center, false)
	await wait_frames(5)
	check(not main.menu.visible and main.level_index == 1, "the tap starts the chosen level")
	check(throws[0] == 0 and not main._running, "the tap that chose the level does not throw")
