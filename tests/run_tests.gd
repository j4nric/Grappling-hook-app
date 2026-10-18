extends SceneTree
## Headless test runner. Runs every res://tests/test_*.gd one after another.
## godot --headless --fixed-fps 60 --path . --script res://tests/run_tests.gd
## Exit code 1 if any check failed, a test file did not load, or a script
## error happened. TEST_FILTER=chain runs only matching files.

const SAVED_FILES := ["user://tuning_v2.cfg", "user://tuning_v3.cfg", "user://tuning_presets.cfg",
		"user://records.cfg", "user://settings.cfg", "user://history.cfg", "user://cave_edits.cfg", "user://stats.cfg"]


## Counts script errors (a broken test or game script must fail the run,
## not just print).
class ErrorCounter extends Logger:
	var count := 0

	func _log_error(_function: String, _file: String, _line: int, _code: String, _rationale: String,
			_editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == ERROR_TYPE_SCRIPT:
			count += 1


var _errors := ErrorCounter.new()


func _initialize() -> void:
	OS.add_logger(_errors)
	_run.call_deferred()


func _run() -> void:
	var names: Array[String] = []
	var filter := OS.get_environment("TEST_FILTER")
	for file in DirAccess.get_files_at("res://tests"):
		if file.begins_with("test_") and file.ends_with(".gd") and file != "test_case.gd" \
				and (filter == "" or file.contains(filter)):
			names.append(file)
	names.sort()

	var failed := 0
	for file in names:
		_clear_saved_state()
		print("  ", file)
		var started := Time.get_ticks_msec()
		var errors_before := _errors.count
		var script: GDScript = load("res://tests/" + file)
		if script == null or not script.can_instantiate():
			print("    FAIL: %s does not load" % file)
			failed += 1
			continue
		var test: Node = script.new()
		root.add_child(test)
		await test.run()
		failed += test.failures.size()
		print("    (%.1f s)" % ((Time.get_ticks_msec() - started) / 1000.0))
		var new_errors := _errors.count - errors_before
		if new_errors > 0:
			print("    FAIL: %d script error(s)" % new_errors)
			failed += new_errors
		test.queue_free()
		paused = false
		await process_frame
		await process_frame
	_clear_saved_state()

	print("%d test files, %d failed checks" % [names.size(), failed])
	quit(1 if failed > 0 else 0)


func _clear_saved_state() -> void:
	Settings.ghost_enabled = true
	Settings.sound_enabled = true
	Settings.apply()
	for path in SAVED_FILES:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	for file in DirAccess.get_files_at("user://"):
		if file.begins_with("ghost_") or file.begins_with("rival_"):
			DirAccess.remove_absolute("user://" + file)
