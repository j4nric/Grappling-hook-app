extends "res://tests/test_case.gd"
## Debug overlay and automatic quality.


func run() -> void:
	await load_main()
	var debug := main.get_node("Debug")
	var view: SubViewportContainer = main.get_node("World/PixelView")
	await wait_frames(3)
	check(not debug._label.visible, "debug overlay is off by default")
	debug.shown = 1.0
	await wait_frames(2)
	check(debug._label.visible and debug._label.text.contains("FPS"), "debug overlay shows FPS")

	# Pretend the frame rate is too low: the pixel view gets coarser.
	var shrink := view.stretch_shrink
	debug.auto_quality = 1.0
	debug.min_fps = 100000.0
	debug.low_fps_time = 0.1
	var dropped := await wait_until(func() -> bool: return view.stretch_shrink != shrink, 30)
	check(dropped and view.stretch_shrink == shrink + 1, "low frame rate lowers the resolution one step (%d -> %d)" % [shrink, view.stretch_shrink])
	view.stretch_shrink = debug.max_shrink
	await wait_frames(20)
	check(view.stretch_shrink == debug.max_shrink, "auto quality stops at max_shrink")
	view.stretch_shrink = shrink
