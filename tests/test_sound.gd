extends "res://tests/test_case.gd"
## Sound effects react to the game; the wind loops and follows the speed.


func run() -> void:
	await load_main()
	var sfx := main.get_node("Sfx")
	var p := player()
	await wait_frames(5)
	for sound_name in sfx.SOUNDS:
		check(sfx._players[sound_name].stream != null, "sound '%s' is loaded" % sound_name)
	check(sfx._wind.stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "wind loops")

	InputRouter.throw_requested.emit(Vector2(0, -300), Vector2(0, -3000))
	check(sfx._players["throw"].playing, "throw makes a sound")
	check(sfx._players["go"].playing, "the run start beeps")
	await wait_until(func() -> bool: return p.hook_state == p.HookState.ATTACHED, 60)
	check(sfx._players["hook"].playing, "hook biting clanks")
	await wait_until(func() -> bool: return p.velocity.length() > 20.0, 120)
	await get_tree().process_frame
	check(sfx._wind.playing and sfx._wind.volume_db > -20.0, "wind is audible at speed")

	main.load_level(1)
	await wait_frames(3)
	sfx._players["checkpoint"].stop()
	p.global_position = Vector3(0, 0, -102)
	await wait_frames(3)
	check(sfx._players["checkpoint"].playing, "reaching a checkpoint dings")
	sfx._players["checkpoint"].stop()
	p.global_position = Vector3(0, 0, -95)
	await wait_frames(3)
	p.global_position = Vector3(0, 0, -102)
	await wait_frames(3)
	check(not sfx._players["checkpoint"].playing, "the same checkpoint dings only once")
