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


## Fixed straight tunnels: mechanics tests need known geometry (ceiling at
## y=9, finish at z=-200, checkpoint and lava in tunnel 2), not the caves.
const TUNNELS: Array[String] = ["res://tests/levels/tunnel_01.tscn", "res://tests/levels/tunnel_02.tscn"]

## Fixed tuning for the mechanics tests in the tunnels: they check how a
## mechanic works, not the current feel, so new defaults tuned on the phone
## do not break them. Tests of the real levels play with the defaults.
const TEST_TUNING := {
	"Player": {"gravity": 22.0, "floor_friction": 25.0, "slide_friction": 6.0, "landing_roll": 0.3,
		"deflect_keep": 1.0, "wall_bounce": 0.2, "wall_kick_up": 4.0, "throw_speed_per_px": 0.015,
		"hook_min_speed": 8.0, "hook_max_speed": 90.0, "hook_gravity": 25.0, "throw_pitch": 50.0,
		"throw_yaw_gain": 1.0, "throw_buffer_time": 0.3, "aim_preview_speed": 50.0, "min_throw_reach": 14.0,
		"aim_assist_angle": 0.0, "aim_time_scale": 1.0, "max_rope_length": 70.0, "min_hook_distance": 3.0,
		"pull_impulse": 6.0, "reel_speed": 8.0, "reel_acceleration": 30.0, "reel_max_speed": 30.0,
		"min_rope_length": 0.5, "rope_end_release": 1.0, "tension_boost": 6.0, "zip_release_distance": 2.5,
		"zip_boost": 3.0, "flyby_release_distance": 6.0, "contact_release_grace": 0.15, "rope_pluck": 0.5,
		"flight_rope_slack": 1.03},
	"CameraRig": {"base_fov": 65.0, "fov_per_speed": 0.4, "max_fov": 90.0, "offset": Vector3(0, 3.5, 10),
		"anchor_look_weight": 0.3, "roll_per_speed": 1.2, "max_roll": 12.0, "shake_strength": 0.35},
}

## The limp fall before a respawn (game.gd fall_show_time): off in tests,
## so a death respawns at once as the tests and the bot's timings expect.
var fall_show_time := 0.0
## Levels the game gets (tests of the real levels use Levels.LIST).
var levels: Array[String] = TUNNELS
## Level the test plays (index into levels).
var level_index := 0


## Index of a level scene ("level_02") in Levels.LIST.
static func level_named(file: String) -> int:
	return Levels.LIST.find("res://scenes/levels/%s.tscn" % file)


func load_main() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	main.level_list = levels
	main.start_level = level_index
	main.fall_show_time = fall_show_time
	if levels == TUNNELS:
		# Before entering the tree: the tuning panel takes these as defaults.
		for node_path: String in TEST_TUNING:
			var node := main.get_node(node_path)
			for property: String in TEST_TUNING[node_path]:
				node.set(property, TEST_TUNING[node_path][property])
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
