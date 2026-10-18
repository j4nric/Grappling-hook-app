extends "res://tests/test_case.gd"
## Pause menu, focus loss, timer step limit, speed limit, wind loop.


func run() -> void:
	await load_main()
	var p := player()
	var pause := main.get_node("PauseMenu")
	await wait_frames(5)

	InputRouter.throw_requested.emit(Vector2(0, -300), Vector2(0, -3000))
	await wait_frames(10)
	pause.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(pause.is_open() and get_tree().paused, "losing focus pauses the game")
	var frozen: float = main._elapsed
	await wait_frames(10)
	check(is_equal_approx(main._elapsed, frozen), "the timer stops while paused")
	pause.close()
	check(not get_tree().paused, "continue resumes")

	# One huge frame (return from the background) adds at most max_timer_step.
	var before: float = main._elapsed
	main._process(5.0)
	check(main._elapsed - before <= main.max_timer_step + 0.001, "a huge frame does not jump the timer")

	# Pause -> Restart and Pause -> Levels.
	pause.open()
	pause._on_restart()
	await wait_frames(2)
	check(not get_tree().paused and absf(p.global_position.z) < 0.5 and not main._running, "pause restart starts over")
	pause.open()
	pause._on_levels()
	check(main.menu.visible, "pause can open the level menu")
	main.menu.close()

	# The zip boost respects the speed limit.
	p.velocity = Vector3(0, 0, -p.max_speed)
	p.hook_state = p.HookState.ATTACHED
	p._zip_launch()
	check(p.velocity.length() <= p.max_speed + 0.01, "zip boost stays within max_speed")

	# The wind loop keeps playing, its volume follows the speed.
	var sfx := main.get_node("Sfx")
	main.restart()
	# The wind level glides down (wind_fade_speed): a second is plenty.
	await wait_frames(60)
	check(sfx._wind.playing and sfx._wind.volume_db < -40.0, "wind plays silently at rest (%s, %.1f dB, %.1f m/s)" % [sfx._wind.playing, sfx._wind.volume_db, p.velocity.length()])
