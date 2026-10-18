extends "res://tests/test_case.gd"
## A fatal fall: the figure tumbles limp for a moment (no input, the timer
## stands), then the respawn at the checkpoint.


func run() -> void:
	fall_show_time = 0.5
	level_index = 1
	await load_main()
	var p := player()
	var figure: PlayerFigure = p.figure
	InputRouter.throw_requested.emit(Vector2(0, -300), Vector2(0, -3000))
	await wait_until(func() -> bool: return p.hook_state == p.HookState.ATTACHED, 60)
	check(main._running, "the run is on")
	var fall_at := p.global_position
	p.velocity = Vector3(0, -5, -20)
	main.level.killed.emit()
	await wait_frames(1)
	check(p.fallen and figure.limp, "lava: the figure goes limp")
	check(p.hook_state == p.HookState.IDLE, "the rope lets go")
	var time: float = main._elapsed
	var figure_at := figure.global_position
	var tilt := figure.basis.y
	InputRouter.throw_requested.emit(Vector2(0, -300), Vector2(0, -3000))
	await wait_frames(12)
	check(p.hook_state == p.HookState.IDLE, "no throws while falling")
	check(p.global_position.distance_to(fall_at) < 0.5, "the body waits")
	check(figure.global_position.z < figure_at.z - 1.0, "the figure flies on limp")
	check(figure.basis.y.angle_to(tilt) > 0.5, "the figure tumbles")
	check(is_equal_approx(main._elapsed, time), "the timer stands during the fall")
	main.level.killed.emit()
	var back := await wait_until(func() -> bool: return not p.fallen, 60)
	check(back and p.global_position.distance_to(main._respawn) < 1.0, "then back at the checkpoint")
	await wait_frames(1)
	check(not figure.limp and figure.global_position.distance_to(p.global_position) < 1.5,
			"the figure is back with the body (%.2f m)" % figure.global_position.distance_to(p.global_position))
	check(main.fade.color.a > 0.8, "the respawn starts black")
	await wait_frames(30)
	check(main._elapsed > time, "the timer runs again")

	# A fall below the depth limit, and a restart in the middle of a fall.
	p.global_position = Vector3(0, main.level.kill_y - 1.0, -20)
	await wait_frames(2)
	check(p.fallen, "falling into the depth goes limp too")
	main.restart()
	check(not p.fallen and main._falling == 0.0, "a restart ends the fall")
