extends "res://tests/test_case.gd"
## Music: three stems in sync, the pulse and the arpeggio come in with speed
## and flow and fade out at rest; the stems loop seamlessly.


func run() -> void:
	for stem in ["music_base", "music_pulse", "music_arp"]:
		var wav: AudioStreamWAV = load("res://assets/music/%s.wav" % stem)
		check(wav != null and wav.loop_mode != AudioStreamWAV.LOOP_DISABLED, "%s loops" % stem)
		check(wav != null and absf(wav.get_length() - 20.0) < 0.1, "%s is one 20 s loop" % stem)
	await load_main()
	var music := main.get_node("Music")
	var p := player()
	await wait_frames(30)
	check(music.is_playing(), "music plays")
	check(music.levels[0] > 0.9 and music.levels[1] < 0.2 and music.levels[2] < 0.1, "at rest only the base plays %s" % [music.levels])
	for i in 180:
		p.velocity = Vector3(0, 0, -45)
		await get_tree().process_frame
	check(music.levels[1] > 0.8 and music.levels[2] > 0.6, "at full speed pulse and arpeggio play %s" % [music.levels])
	main.restart()
	# After the landing on the start ledge (a landing ends the flow).
	await wait_frames(30)
	main.flow = music.arp_flow
	for i in 120:
		p.velocity = Vector3.ZERO
		await get_tree().process_frame
	check(music.levels[2] > 0.6, "a long flow chain keeps the arpeggio %s" % [music.levels])
	main.flow = 0
	for i in 240:
		await get_tree().process_frame
	check(music.levels[1] < 0.2 and music.levels[2] < 0.2, "back at rest it calms down %s" % [music.levels])
