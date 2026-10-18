extends "res://tests/test_case.gd"
## Progress: medals in the level menu, the daily streak, splits on the
## finish screen, outfits unlocked by medals, a backup code of all progress.


func run() -> void:
	levels = Levels.with_procedural()
	await load_main()

	# Outfits: only the first at the start; two gold medals unlock "Ember".
	var medals := Outfits.best_medals()
	check(Outfits.unlocked_names(medals) == ["Classic"], "one outfit at the start")
	for file in ["level_01", "level_02"]:
		var path := "res://scenes/levels/%s.tscn" % file
		var scene: Level = Levels.instantiate(path)
		Records.submit(Records.id(path, scene), scene.gold_time - 0.5)
		scene.free()
	medals = Outfits.best_medals()
	var names := Outfits.unlocked_names(medals)
	check("Ember" in names and not "Moss" in names, "two gold medals unlock Ember, not Moss (3 bronze) (%s)" % [names])
	check(Outfits.requirement(Outfits.find("Golden")) == "gold in every level", "the last outfit needs gold everywhere")
	var pause = main.pause_menu
	pause.open()
	var jacket_before: Color = player().figure._jacket[0].albedo_color
	pause.next_outfit()
	check(Settings.outfit == names[1], "the pause menu switches to the next unlocked outfit (%s)" % Settings.outfit)
	await wait_frames(1)
	check(player().figure._jacket[0].albedo_color != jacket_before, "the climber wears it")
	check(pause._status.text.contains("Next outfit"), "it says what the next locked outfit needs")
	pause.next_outfit()
	pause.close()

	# Level menu: medal marks and the summary.
	main.open_menu()
	var buttons: Array = main.menu._list.get_children()
	check(buttons.size() == main.level_list.size() and (buttons[2] as Button).icon != null, "each level has a medal mark")
	check(main.menu._summary.text.begins_with("Gold 2"), "the summary counts the medals (%s)" % main.menu._summary.text)

	# Daily streak, across a month end.
	for day in [20261030, 20261031, 20261101]:
		Stats.add_daily_day(day)
	check(Stats.daily_streak(20261101) == 3, "three days in a row")
	check(Stats.daily_streak(20261102) == 3, "today may still come: the streak holds")
	check(Stats.daily_streak(20261104) == 0, "a missed day ends it")
	main.menu.close()

	# Splits against the best run.
	var text: String = main.splits_text([10.0, 20.5], [10.5, 20.0])
	check(text == "Checkpoint 1   10.00   -0.50\nCheckpoint 2   20.50   +0.50", "the finish lists the splits (%s)" % text)

	# Backup: all progress as a code, back after the files are gone.
	Stats.add("level_01", {"runs": 7})
	var backup := Backup.code()
	check(backup.begins_with("GCB1:") and backup.length() < 20000, "a backup code (%d characters)" % backup.length())
	for path: String in Backup.FILES:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	check(Outfits.unlocked_names(Outfits.best_medals()) == ["Classic"], "progress gone")
	var message: String = main.restore_backup("my backup: " + backup)
	check(message.begins_with("Restored"), "the code restores (%s)" % message)
	check("Ember" in Outfits.unlocked_names(Outfits.best_medals()) and Stats.of("level_01").runs == 7, "medals and stats are back (%s, %s)" % [Outfits.unlocked_names(Outfits.best_medals()), Stats.of("level_01")])
	check(Stats.daily_streak(20261101) == 3, "the streak is back")
	check(main.restore_backup("nothing").begins_with("No backup"), "text without a code is refused")
	check(Backup.is_plain([1, "a", {"b": 2.0}, PackedStringArray(["c"])]) and not Backup.is_plain(RefCounted.new()) \
			and not Backup.is_plain([RefCounted.new()]), "only plain values come in")
	Settings.outfit = "Classic"
	Settings.save_settings()
