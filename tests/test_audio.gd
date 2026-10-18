extends "res://tests/test_case.gd"
## Spatial sound: the cave places 3D sounds at lava, updrafts, crystals and
## drips; loops loop; only sounds near the listener play; effects carry a
## baked cave reverb tail.


func run() -> void:
	for sound_name in ["amb_lava", "amb_updraft", "amb_crystal"]:
		var stream: AudioStreamWAV = load("res://assets/sounds/%s.wav" % sound_name)
		check(stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "%s loops" % sound_name)
	# Reverb tail: the hook bite rings on well after its attack.
	var hook: AudioStreamWAV = load("res://assets/sounds/hook.wav")
	check(hook.get_length() > 0.6, "hook sound has a reverb tail (%.2f s)" % hook.get_length())

	levels = Levels.LIST
	level_index = level_named("level_02")
	await load_main()
	var sounds := _sounds(main.level)
	for kind in ["Lava", "Crystal", "Drip"]:
		check(sounds.any(func(s: AmbientSound) -> bool: return s.name.begins_with(kind)), "level_02 has %s sounds" % kind)
	var drips := sounds.filter(func(s: AmbientSound) -> bool: return not s.is_loop())
	check(drips.size() >= 2 * (main.level.segments as Array).size(), "two drips per hall (%d)" % drips.size())

	main.load_level(level_named("level_06"))
	await wait_frames(2)
	sounds = _sounds(main.level)
	check(sounds.any(func(s: AmbientSound) -> bool: return s.name.begins_with("Updraft")), "level_06 has updraft sounds")

	# Only sounds within reach of the listener play.
	await wait_frames(30)
	var cam := main.get_viewport().get_camera_3d()
	var near := 0
	var far_playing := 0
	for s: AmbientSound in sounds:
		if not s.is_loop():
			continue
		var distance := cam.global_position.distance_to(s.global_position)
		if distance < s.max_distance * 0.9 and s.playing:
			near += 1
		elif distance > s.max_distance * 1.1 and s.playing:
			far_playing += 1
	check(far_playing == 0, "distant loops are silent (%d playing)" % far_playing)
	var loops := sounds.filter(func(s: AmbientSound) -> bool: return s.is_loop())
	check(loops.size() > near, "not every loop of the cave plays at once (%d of %d)" % [near, loops.size()])


func _sounds(level: Node) -> Array:
	return level.get_node("Sounds").get_children().filter(func(n: Node) -> bool: return n is AmbientSound)
