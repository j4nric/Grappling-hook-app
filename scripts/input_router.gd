extends Node
## Autoload "InputRouter".
## Unifies desktop (mouse) and iOS (touch) input into gameplay signals so
## that the player never has to know which device it runs on.
##
## Desktop:  left click  -> grapple at mouse position
##           right click -> release
##           R           -> restart level
## Touch:    swipe       -> grapple at swipe end point (swipe vector + duration
##                          are passed along for the later "throw" feel)
##           tap         -> release
##           two-finger tap -> restart level

signal grapple_requested(screen_pos: Vector2, swipe: Vector2, duration: float)
signal release_requested
signal restart_requested

## Below this distance (px) and duration (s) a touch counts as a tap.
const TAP_MAX_DISTANCE := 24.0
const TAP_MAX_DURATION := 0.25
## Visible Controls in this group swallow touches and clicks (tuning panel).
const BLOCKING_GUI_GROUP := "blocks_gameplay_input"

var _touch_active := false
var _touch_start_pos := Vector2.ZERO
var _touch_start_time := 0.0
var _touch_count := 0
## Set once a second finger touches; the gesture then only counts as restart.
var _multi_touch := false


func _ready() -> void:
	# Keep tracking touches while the game is paused so the counts stay right.
	process_mode = Node.PROCESS_MODE_ALWAYS


func _unhandled_input(event: InputEvent) -> void:
	if get_tree().paused and not event is InputEventScreenTouch:
		return
	# --- Desktop -----------------------------------------------------------
	# Mouse events emulated from touch are skipped; touches are handled below.
	if event is InputEventMouseButton and event.pressed \
			and event.device != InputEvent.DEVICE_ID_EMULATION \
			and not _is_over_gui(event.position):
		if event.button_index == MOUSE_BUTTON_LEFT:
			grapple_requested.emit(event.position, Vector2.ZERO, 0.0)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			release_requested.emit()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_R:
		restart_requested.emit()

	# --- Touch ---------------------------------------------------------------
	elif event is InputEventScreenTouch:
		if event.pressed:
			_touch_count += 1
			if get_tree().paused or _is_over_gui(event.position):
				return
			if event.index == 0:
				_touch_active = true
				_multi_touch = false
				_touch_start_pos = event.position
				_touch_start_time = _now()
			else:
				_multi_touch = true
			return
		_touch_count = maxi(0, _touch_count - 1)
		if _multi_touch:
			_touch_active = false
			if _touch_count == 0:
				_multi_touch = false
				restart_requested.emit()
		elif event.index == 0 and _touch_active:
			_touch_active = false
			var swipe: Vector2 = event.position - _touch_start_pos
			var duration: float = _now() - _touch_start_time
			if swipe.length() < TAP_MAX_DISTANCE and duration < TAP_MAX_DURATION:
				release_requested.emit()
			else:
				grapple_requested.emit(event.position, swipe, duration)


func _is_over_gui(pos: Vector2) -> bool:
	for node in get_tree().get_nodes_in_group(BLOCKING_GUI_GROUP):
		var control := node as Control
		if control and control.is_visible_in_tree() and control.get_global_rect().has_point(pos):
			return true
	return false


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0
