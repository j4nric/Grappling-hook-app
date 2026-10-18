extends "res://tests/test_case.gd"
## Real touch events through Input, like a phone sends them at 60 fps.
## iOS Safari uses arbitrary touch indices, so none of these use index 0.

var _throws: Array = []


func run() -> void:
	await load_main()
	InputRouter.throw_requested.connect(_on_throw)
	await wait_frames(20)
	var start := Vector2(360, 1000)

	await swipe(4711, start, repeat(Vector2(6, -45), 6))
	check(_throws.size() == 1, "fast flick throws once")
	if _throws.size() > 0:
		var flick: Vector2 = _throws[-1][1]
		check(flick.length() > 2000.0, "fast flick speed measured (%.0f px/s)" % flick.length())
		check(_throws[-1][0].x > 0.0, "swipe direction kept")

	await swipe(4712, start, repeat(Vector2(0, -8), 30))
	if _throws.size() > 1:
		check(_throws[-1][1].length() < 700.0, "slow drag gives a weak throw (%.0f px/s)" % _throws[-1][1].length())

	await swipe(4713, start, repeat(Vector2(0, -45), 6), 20)
	if _throws.size() > 2:
		check(_throws[-1][1].length() < 1.0, "flick then hold gives no flick speed")
	check(_throws.size() == 3, "three swipes, three throws (%d)" % _throws.size())

	# A tap right after the hook bites is ignored, a later tap lets go.
	var p := player()
	main.restart()
	await wait_frames(20)
	InputRouter.throw_requested.emit(Vector2(0, -300), Vector2(0, -3000))
	await wait_until(func() -> bool: return p.hook_state == p.HookState.ATTACHED, 60)
	await _tap(9001, start)
	check(p.hook_state == p.HookState.ATTACHED, "tap right after the hook bites is ignored")
	main.restart()
	await wait_frames(20)
	InputRouter.throw_requested.emit(Vector2(0, -300), Vector2(0, -3000))
	await wait_until(func() -> bool: return p.hook_state == p.HookState.ATTACHED, 60)
	await wait_frames(int(p.tap_release_lock * 60) + 2)
	await _tap(9002, start)
	check(p.hook_state == p.HookState.IDLE, "a later tap lets go of the rope")

	# A tap does not start the run timer.
	main.restart()
	await wait_frames(5)
	await _tap(9003, start)
	await wait_frames(10)
	check(not main._running, "a tap does not start the timer")

	# A short but quick flick is a throw, not a tap.
	var before := _throws.size()
	await swipe(4720, start, [Vector2(0, -15)])
	check(_throws.size() == before + 1, "short quick flick throws")

	# Two fingers: a quick tap does nothing, holding restarts.
	main.restart()
	InputRouter.throw_requested.emit(Vector2(0, -300), Vector2(0, -3000))
	await wait_frames(30)
	var throws_before := _throws.size()
	touch(31, Vector2(200, 900), true)
	touch(32, Vector2(500, 900), true)
	await get_tree().process_frame
	touch(31, Vector2(200, 900), false)
	touch(32, Vector2(500, 900), false)
	await wait_frames(2)
	check(absf(p.global_position.z) > 0.5, "a quick two-finger tap does not restart")
	touch(33, Vector2(200, 900), true)
	touch(34, Vector2(500, 900), true)
	await wait_frames(int(InputRouter.RESTART_HOLD * 60) + 3)
	check(absf(p.global_position.z) < 0.1, "holding two fingers restarts")
	touch(33, Vector2(200, 900), false)
	touch(34, Vector2(500, 900), false)
	await wait_frames(2)
	check(_throws.size() == throws_before, "two-finger gestures throw nothing")

	# A second finger on a button while aiming is no restart gesture.
	var tune: Control = main.get_node("Tuning")._toggle
	var on_button := tune.get_global_rect().get_center()
	touch(40, start, true)
	drag(40, start + Vector2(0, -80))
	await get_tree().process_frame
	touch(41, on_button, true)
	await wait_frames(int(InputRouter.RESTART_HOLD * 60) + 5)
	touch(41, on_button, false)
	check(InputRouter._aiming, "second finger on a button keeps the aim")
	touch(40, start + Vector2(0, -80), false)
	await wait_frames(2)
	check(_throws.size() == throws_before + 1, "the aim still throws")


func _tap(index: int, pos: Vector2) -> void:
	touch(index, pos, true)
	await get_tree().process_frame
	touch(index, pos, false)
	await wait_frames(2)


func _on_throw(swipe_vec: Vector2, flick: Vector2) -> void:
	_throws.append([swipe_vec, flick])
