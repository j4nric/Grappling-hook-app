extends Node
## Base for headless tests. A test overrides run() and reports with check().
## Run all tests: godot --headless --fixed-fps 60 --path . --script res://tests/run_tests.gd

var failures: Array[String] = []
var main: Node


func run() -> void:
	pass


func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		print("    FAIL: ", message)


func load_main() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame


func player() -> CharacterBody3D:
	return main.get_node("Player")


func wait_frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame


## Waits until the condition holds, at most max_frames. Returns whether it held.
func wait_until(condition: Callable, max_frames: int) -> bool:
	for i in max_frames:
		if condition.call():
			return true
		await get_tree().physics_frame
	return condition.call()


# --- Input (positions in the 720 px wide game viewport) ----------------------

func _to_window(pos: Vector2) -> Vector2:
	return get_tree().root.get_final_transform() * pos


func touch(index: int, pos: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = _to_window(pos)
	event.pressed = pressed
	Input.parse_input_event(event)


func drag(index: int, pos: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = _to_window(pos)
	Input.parse_input_event(event)


## Swipe one frame per step; moves is a list of per-frame offsets.
## hold_frames: finger rests before letting go.
func swipe(index: int, start: Vector2, moves: Array, hold_frames := 0) -> void:
	var pos := start
	touch(index, pos, true)
	await get_tree().process_frame
	for m in moves:
		pos += m
		drag(index, pos)
		await get_tree().process_frame
	for i in hold_frames:
		await get_tree().process_frame
	touch(index, pos, false)
	await get_tree().process_frame


static func repeat(offset: Vector2, count: int) -> Array:
	var moves := []
	for i in count:
		moves.append(offset)
	return moves
