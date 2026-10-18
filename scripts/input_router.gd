extends Node
## Autoload "InputRouter".
## Unifies desktop (mouse) and iOS (touch) input into gameplay signals so
## that the player never has to know which device it runs on.
##
## Both devices share one gesture, like throwing a Pokéball in Pokémon GO:
##   press + drag      -> aim (aim_changed with the swipe vector)
##   let go            -> throw the hook (throw_requested with the swipe vector
##                        and the flick velocity of the last FLICK_WINDOW)
##   tap               -> let go of the rope
## Extra:   hold two fingers (RESTART_HOLD) / R -> restart, right click -> let go

signal aim_changed(swipe: Vector2)
signal aim_cancelled
signal throw_requested(swipe: Vector2, flick_velocity: Vector2)
signal release_requested
signal restart_requested

## Below this distance (px) and duration (s) a touch counts as a tap ...
const TAP_MAX_DISTANCE := 20.0
const TAP_MAX_DURATION := 0.25
## ... unless the finger moved faster than this (px/s): a short quick flick is
## a throw, not a tap.
const TAP_MAX_FLICK := 500.0
## Two fingers held this long (s) restart the level. A hold instead of a tap,
## so a palm or a second finger on a button does not restart by accident.
const RESTART_HOLD := 0.3
## The throw strength comes from the finger speed over this trailing window (s).
const FLICK_WINDOW := 0.1
## Visible Controls in this group swallow touches and clicks (tuning panel).
const BLOCKING_GUI_GROUP := "blocks_gameplay_input"

var _pointer_down := false
var _aiming := false
var _start_pos := Vector2.ZERO
var _start_time := 0.0
## Recent pointer samples as (x, y, time) for the flick velocity.
var _samples: Array[Vector3] = []
## Touch indices of the current gesture. Never assume the first finger is
## index 0: iOS Safari reports large arbitrary touch identifiers.
var _touches := {}
## Index of the finger that aims and throws, -1 if none.
var _primary_touch := -1
## Set once a second finger touches; the gesture then only counts as restart.
var _multi_touch := false
## Clock time when the second finger came down, -1 if no restart is pending.
var _restart_from := -1.0
## Unscaled frame clock (s). Frame time instead of wall time keeps slow motion
## out of the flick speed and makes headless tests with --fixed-fps exact.
var _clock := 0.0


func _ready() -> void:
	# Keep tracking touches while the game is paused so the counts stay right.
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Every drag sample counts for the flick speed; accumulated input would
	# merge the fast last part of a flick into the release position.
	Input.use_accumulated_input = false


func _process(delta: float) -> void:
	_clock += delta / maxf(Engine.time_scale, 0.001)
	if _restart_from >= 0.0 and _touches.size() >= 2 and _now() - _restart_from >= RESTART_HOLD:
		_restart_from = -1.0
		restart_requested.emit()


func _unhandled_input(event: InputEvent) -> void:
	# Mouse events emulated from touch are skipped; touches are handled below.
	if event.device == InputEvent.DEVICE_ID_EMULATION:
		return
	if event is InputEventScreenTouch:
		_handle_touch(event)
		return
	if get_tree().paused:
		return

	if event is InputEventScreenDrag:
		if event.index == _primary_touch and not _multi_touch:
			_pointer_moved(event.position)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_pointer_pressed(event.position)
			else:
				_pointer_released(event.position)
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			release_requested.emit()
	elif event is InputEventMouseMotion and _touches.is_empty():
		_pointer_moved(event.position)
	elif event is InputEventKey and event.pressed and event.keycode == KEY_R:
		restart_requested.emit()


func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if _primary_touch == -1:
			# New gesture; also drops touches whose release got lost.
			_touches = {event.index: true}
			_primary_touch = event.index
			_multi_touch = false
			_pointer_pressed(event.position)
		elif not _is_over_gui(event.position):
			# A second finger on a button (TUNE, pause) is not a gesture.
			_touches[event.index] = true
			_multi_touch = true
			_restart_from = _now()
			_cancel_aim()
		return

	_touches.erase(event.index)
	if _multi_touch:
		_pointer_down = false
		_restart_from = -1.0
		if _touches.is_empty():
			_multi_touch = false
			_primary_touch = -1
	elif event.index == _primary_touch:
		_primary_touch = -1
		_pointer_released(event.position)


func _pointer_pressed(pos: Vector2) -> void:
	if get_tree().paused or _is_over_gui(pos):
		return
	_pointer_down = true
	_aiming = false
	_multi_touch = false
	_start_pos = pos
	_start_time = _now()
	_samples.clear()
	_add_sample(pos)


func _pointer_moved(pos: Vector2) -> void:
	if not _pointer_down:
		return
	_add_sample(pos)
	var swipe := pos - _start_pos
	if not _aiming and swipe.length() >= TAP_MAX_DISTANCE:
		_aiming = true
	if _aiming:
		aim_changed.emit(swipe)


func _pointer_released(pos: Vector2) -> void:
	if not _pointer_down:
		return
	_pointer_down = false
	_add_sample(pos)
	var swipe := pos - _start_pos
	var flick := _flick_velocity()
	if swipe.length() < TAP_MAX_DISTANCE and flick.length() < TAP_MAX_FLICK:
		_cancel_aim()
		if _now() - _start_time < TAP_MAX_DURATION:
			release_requested.emit()
		return
	_aiming = false
	throw_requested.emit(swipe, flick)


func _cancel_aim() -> void:
	if _aiming:
		_aiming = false
		aim_cancelled.emit()


func _add_sample(pos: Vector2) -> void:
	var now := _now()
	_samples.append(Vector3(pos.x, pos.y, now))
	while _samples.size() > 2 and now - _samples[0].z > FLICK_WINDOW:
		_samples.pop_front()


## Finger velocity (px/s) over the last FLICK_WINDOW. A finger that stopped
## before letting go gives a weak throw, just like in Pokémon GO.
func _flick_velocity() -> Vector2:
	if _samples.size() < 2:
		return Vector2.ZERO
	var first := _samples[0]
	var last := _samples[-1]
	# Ignore samples older than the window (finger rested before the flick).
	for s in _samples:
		if last.z - s.z <= FLICK_WINDOW:
			first = s
			break
	var dt := maxf(last.z - first.z, 1.0 / 60.0)
	return Vector2(last.x - first.x, last.y - first.y) / dt


func _is_over_gui(pos: Vector2) -> bool:
	for node in get_tree().get_nodes_in_group(BLOCKING_GUI_GROUP):
		var control := node as Control
		if control and control.is_visible_in_tree() and control.get_global_rect().has_point(pos):
			return true
	return false


func _now() -> float:
	return _clock
