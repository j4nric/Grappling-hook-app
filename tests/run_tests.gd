extends SceneTree
## Headless test runner. Runs every res://tests/test_*.gd one after another.
## godot --headless --fixed-fps 60 --path . --script res://tests/run_tests.gd
## Exit code 1 if any check failed.

const SAVED_FILES := ["user://tuning_v2.cfg", "user://tuning_v3.cfg", "user://records.cfg"]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var names: Array[String] = []
	for file in DirAccess.get_files_at("res://tests"):
		if file.begins_with("test_") and file.ends_with(".gd") and file != "test_case.gd":
			names.append(file)
	names.sort()

	var failed := 0
	for file in names:
		_clear_saved_state()
		print("  ", file)
		var test: Node = load("res://tests/" + file).new()
		root.add_child(test)
		await test.run()
		failed += test.failures.size()
		test.queue_free()
		paused = false
		await process_frame
		await process_frame
	_clear_saved_state()

	print("%d test files, %d failed checks" % [names.size(), failed])
	quit(1 if failed > 0 else 0)


func _clear_saved_state() -> void:
	for path in SAVED_FILES:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	for file in DirAccess.get_files_at("user://"):
		if file.begins_with("ghost_"):
			DirAccess.remove_absolute("user://" + file)
