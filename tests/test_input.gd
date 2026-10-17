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

	# Tap lets go of the rope.
	var p := player()
	InputRouter.throw_requested.emit(Vector2(0, -300), Vector2(0, -3000))
	await wait_until(func() -> bool: return p.hook_state == p.HookState.ATTACHED, 60)
	touch(9001, start, true)
	await get_tree().process_frame
	touch(9001, start, false)
	await wait_frames(2)
	check(p.hook_state == p.HookState.IDLE, "tap lets go of the rope")

	# Two-finger tap restarts.
	await wait_frames(30)
	var throws_before := _throws.size()
	touch(31, Vector2(200, 900), true)
	touch(32, Vector2(500, 900), true)
	await get_tree().process_frame
	touch(31, Vector2(200, 900), false)
	touch(32, Vector2(500, 900), false)
	await wait_frames(2)
	check(absf(p.global_position.z) < 0.1, "two-finger tap resets the player")
	check(_throws.size() == throws_before, "two-finger tap throws nothing")


func _on_throw(swipe_vec: Vector2, flick: Vector2) -> void:
	_throws.append([swipe_vec, flick])
