extends "res://tests/test_case.gd"
## The main scene runs, the HUD shows the timer and the hint.


func run() -> void:
	await load_main()
	await wait_frames(60)
	check(main.get_node("HUD/Safe/TimeLabel").text == "0.00", "timer waits for the first input")
	check(main.get_node("HUD/Safe/HintLabel").text != "", "hint is shown")
	check(main.get_node("HUD/Safe/VersionLabel").text.begins_with("build "), "build version is shown")
