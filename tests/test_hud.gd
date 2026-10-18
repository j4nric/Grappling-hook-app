extends "res://tests/test_case.gd"
## HUD: controls hint, finish screen, safe area, tuning values as text.


func run() -> void:
	await load_main()
	var p := player()
	var hint: Label = main.get_node("HUD/Safe/HintLabel")
	var panel: Control = main.get_node("HUD/Safe/FinishPanel")
	await wait_frames(10)

	check(hint.text != "", "controls hint shows at the start")
	InputRouter.throw_requested.emit(Vector2(0, -300), Vector2(0, -3000))
	await wait_until(func() -> bool: return p.hook_state == p.HookState.ATTACHED, 60)
	check(hint.text == "", "hint disappears after the first hook")
	main.restart()
	check(hint.text == "", "hint stays away after a restart")

	# Finish: the finish screen shows the time, any input plays again.
	InputRouter.throw_requested.emit(Vector2(0, -300), Vector2(0, -3000))
	await wait_frames(30)
	p.global_position = Vector3(0, 0, -200)
	await wait_frames(3)
	check(panel.visible, "finish screen appears at the finish line")
	check(main.get_node("HUD/Safe/FinishPanel/Lines/Best").text == "New best!", "first finish is a new best")
	check(main.get_node("HUD/Safe/BestLabel").text.begins_with("Best "), "best time shows in the HUD")
	InputRouter.release_requested.emit()
	await wait_frames(2)
	check(not panel.visible, "tap after the finish plays again")
	check(absf(p.global_position.z) < 0.5, "play again starts at the beginning")

	# Safe area: at least the minimum margins.
	var safe: Control = main.get_node("HUD/Safe")
	check(safe.offset_top >= SafeArea.MIN_TOP and -safe.offset_bottom >= SafeArea.MIN_BOTTOM, "HUD keeps clear of the screen edges")

	# Tuning values as text for copying.
	var tuning := main.get_node("Tuning")
	check(tuning.values_text().contains("all values at default"), "values text without changes")
	tuning._sliders["Player/gravity"].value = 30.0
	check(tuning.values_text().contains("Player/gravity = 30"), "values text lists changed values")

	# Tutorial: hints change along the way.
	levels = Levels.LIST
	main.level_list = Levels.LIST
	main.load_level(level_named("level_00"))
	await wait_frames(3)
	var tutorial_hint: Label = main.get_node("HUD/Safe/HintLabel")
	check(tutorial_hint.text.begins_with("Swipe up"), "tutorial starts with the throw hint (%s)" % tutorial_hint.text)
	InputRouter.throw_requested.emit(Vector2(0, -300), Vector2(0, -3000))
	await wait_frames(2)
	player().global_position = Vector3(0, 10, -100)
	await wait_frames(3)
	check(tutorial_hint.text.begins_with("Ice does not hold"), "further in, the ice hint shows (%s)" % tutorial_hint.text)
