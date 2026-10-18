extends "res://tests/test_case.gd"
## Tuning panel persistence: only changed values are saved, a changed code
## default drops the saved value, the old v2 file is migrated.


func run() -> void:
	var legacy := ConfigFile.new()
	legacy.set_value("tuning", "Player/gravity", 30.0)
	legacy.set_value("tuning", "Player/min_rope_length", 2.5)
	legacy.set_value("tuning", "Player/reel_speed", 10.0)
	legacy.save("user://tuning_v2.cfg")

	await load_main()
	var tuning := main.get_node("Tuning")
	check(is_equal_approx(player().gravity, 30.0), "legacy tuned value is migrated")
	check(not is_equal_approx(player().min_rope_length, 2.5), "legacy old default is dropped")
	check(tuning._toggle.text == "TUNE*", "TUNE* marks tuned values")
	tuning._save()

	var saved := ConfigFile.new()
	saved.load("user://tuning_v3.cfg")
	check(saved.get_section_keys("tuning") == PackedStringArray(["Player/gravity"]), "only changed values are saved")

	main.free()
	await load_main()
	check(is_equal_approx(player().gravity, 30.0), "saved value is loaded again")

	saved.set_value("defaults", "Player/gravity", 18.0)
	saved.save("user://tuning_v3.cfg")
	main.free()
	await load_main()
	check(not is_equal_approx(player().gravity, 30.0), "changed code default wins over the saved value")
	check(main.get_node("Tuning")._toggle.text == "TUNE", "TUNE without star at defaults")

	# Every slider explains itself: a plain name, a text and a sketch.
	var t := main.get_node("Tuning")
	var titles := {}
	for p in t.PARAMS:
		var key: String = "%s/%s" % [p[0], p[1]]
		var info: Array = TuningInfo.PARAMS.get(key, [])
		check(info.size() == 4 and info[0] != "" and info[3].length() > 20, "%s has a name and an explanation" % key)
		if info.size() == 4:
			check(info[2] in TuningIllustration.KINDS, "%s has a known sketch (%s)" % [key, info[2]])
			check(not titles.has(info[0]), "%s: the name '%s' is unique" % [key, info[0]])
			titles[info[0]] = true
	check(TuningInfo.PARAMS.size() == t.PARAMS.size(), "no explanation without a slider")
	# Each sketch draws (script errors fail the test run), with extreme values too.
	t._set_open(true)
	var drawn: int = t._illustration.draw_count
	for p in t.PARAMS:
		t._select(p)
		await wait_frames(2)
		t._sliders["%s/%s" % [p[0], p[1]]].value = p[3]
		await wait_frames(1)
		t._sliders["%s/%s" % [p[0], p[1]]].value = p[2]
		await wait_frames(1)
	check(t._illustration.draw_count >= drawn + t.PARAMS.size(), "every sketch is drawn (%d)" % (t._illustration.draw_count - drawn))
	t._reset()
	var last: Array = t.PARAMS[-1]
	check(t.selected_key() == "%s/%s" % [last[0], last[1]], "selecting a slider explains it")
	check(t._info_text.text.contains(TuningInfo.PARAMS["%s/%s" % [last[0], last[1]]][3]), "the explanation is shown")
	check(t._labels["Player/hook_gravity"].text.begins_with("Hook drop"), "rows show the plain name")
	t._set_open(false)
