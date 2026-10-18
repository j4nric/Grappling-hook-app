extends "res://tests/test_case.gd"
## Replay of the best run (position, rope, respawn jumps, stop by tap) and
## play statistics (counted per run, shown in the level menu).


func run() -> void:
	await load_main()
	var p := player()
	var path: String = levels[0]
	var group := Stats.group(path)
	var before := Stats.of(group)
	var total_before := Stats.of(Stats.TOTAL)
	await wait_frames(5)

	# A run: the ghost records position and rope; stats count it.
	InputRouter.throw_requested.emit(Vector2(0, -300), Vector2(0, -3000))
	var hooked := await wait_until(func() -> bool: return p.hook_state == p.HookState.ATTACHED, 60)
	check(hooked, "the hook bites")
	await wait_frames(20)
	var recording: Dictionary = main.ghost.recording()
	var anchors: PackedVector3Array = recording.anchors
	check(anchors.size() == (recording.positions as PackedVector3Array).size(), "one anchor per sample")
	check(Array(anchors).any(func(a: Vector3) -> bool: return a.is_finite()), "the rope is recorded")
	check(not anchors[0].is_finite(), "no rope before the hook bites")
	p.global_position = Vector3(0, 0, main.level.finish_z())
	await wait_frames(3)
	check(main._finished, "finish reached")
	var after := Stats.of(group)
	check(after.runs == before.runs + 1 and after.finishes == before.finishes + 1, "the run and the finish are counted")
	check(after.hooks > before.hooks, "hooks are counted")
	check(after.meters > before.meters + 5.0, "meters are counted (%.0f m)" % (after.meters - before.meters))
	check(after.play_time > before.play_time, "play time is counted")
	check(after.meters - before.meters < 2.0 * absf(main.level.finish_z()) + 100.0, "the jump to the finish is no flown distance")
	check(Stats.of(Stats.TOTAL).runs == total_before.runs + 1, "the total counts too")

	# Replay from the finish screen.
	var replay_button: Button = main.get_node("HUD/Safe/FinishPanel/Lines/Buttons/Replay")
	check(replay_button.visible, "the finish screen offers the replay")
	var run: Dictionary = Records.load_ghost(Records.id(path, main.level))
	var positions: PackedVector3Array = run.positions
	main.start_replay()
	check(main.replay.is_playing() and p.replaying, "replay runs")
	check(not main.finish_panel.visible and main.replay_label.visible, "finish screen gives way to the replay")
	await wait_frames(30)
	var expected := positions[mini(int(main.replay.time / Ghost.SAMPLE_TIME), positions.size() - 1)]
	check(p.global_position.distance_to(expected) < 3.0, "the player follows the recording (%.2f m off)" % p.global_position.distance_to(expected))
	InputRouter.release_requested.emit()
	await get_tree().process_frame
	check(not main.replay.is_playing() and not p.replaying, "a tap stops the replay")
	check(main.finish_panel.visible and not main.replay_label.visible, "back to the finish screen")
	check(main._finished, "stopping the replay does not restart the level")

	# A respawn in the recording is a jump, not a flight; the replay ends.
	var jump_run := {
		"positions": PackedVector3Array([Vector3(0, 2, 0), Vector3(0, 2, -1), Vector3(0, 2, -80), Vector3(0, 2, -81)]),
		"anchors": PackedVector3Array([Ghost.NO_ANCHOR, Vector3(0, 9, -10), Ghost.NO_ANCHOR, Ghost.NO_ANCHOR]),
	}
	main.replay.start(jump_run)
	var farthest_between := 0.0
	var ended := false
	var roped := false
	for i in 90:
		await get_tree().physics_frame
		roped = roped or (p.hook_state == p.HookState.ATTACHED and p.anchor == Vector3(0, 9, -10))
		var z: float = p.global_position.z
		if z < -1.5 and z > -79.5:
			farthest_between = maxf(farthest_between, -z)
		if not main.replay.is_playing():
			ended = true
			break
	check(farthest_between == 0.0, "no flight across a respawn (at z %.1f)" % -farthest_between)
	check(ended, "the replay ends after the recording")
	check(roped, "the recorded rope is shown")

	# Old ghosts (positions only) still play.
	var old_id := "level_99@00000000"
	var file := FileAccess.open(Records._ghost_path(old_id), FileAccess.WRITE)
	file.store_var(PackedVector3Array([Vector3.ZERO, Vector3.ONE]))
	file = null
	var old := Records.load_ghost(old_id)
	check(Replay.can_play(old) and (old.anchors as PackedVector3Array).is_empty(), "old ghosts load")
	DirAccess.remove_absolute(Records._ghost_path(old_id))

	# Stats screen in the level menu.
	main.open_menu()
	main.menu._toggle_stats()
	check(main.menu.is_showing_stats(), "the menu shows the stats")
	var text: String = main.menu._stats_label.text
	check(text.begins_with("TOTAL") and text.contains(main.level.level_name.to_upper()), "total and level stats are listed")
	main.menu._toggle_stats()
	check(not main.menu.is_showing_stats(), "back to the levels")
	check(Stats.describe({"runs": 3, "finishes": 1, "meters": 2400.0, "hooks": 50, "best_flow": 7, "play_time": 3725.0}) \
			== "3 runs (1 finished)  2.4 km  50 hooks  flow x7  1 h 2 min", "stats read well")
	main.menu.close()
