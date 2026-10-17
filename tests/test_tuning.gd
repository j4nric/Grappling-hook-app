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
