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

signal grapple_requested(screen_pos: Vector2, swipe: Vector2, duration: float)
signal release_requested
signal restart_requested

## Below this distance (px) and duration (s) a touch counts as a tap.
const TAP_MAX_DISTANCE := 24.0
const TAP_MAX_DURATION := 0.25

var _touch_active := false
var _touch_start_pos := Vector2.ZERO
var _touch_start_time := 0.0


func _unhandled_input(event: InputEvent) -> void:
	# --- Desktop -----------------------------------------------------------
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			grapple_requested.emit(event.position, Vector2.ZERO, 0.0)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			release_requested.emit()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_R:
		restart_requested.emit()

	# --- Touch ---------------------------------------------------------------
	elif event is InputEventScreenTouch and event.index == 0:
		if event.pressed:
			_touch_active = true
			_touch_start_pos = event.position
			_touch_start_time = _now()
		elif _touch_active:
			_touch_active = false
			var swipe: Vector2 = event.position - _touch_start_pos
			var duration: float = _now() - _touch_start_time
			if swipe.length() < TAP_MAX_DISTANCE and duration < TAP_MAX_DURATION:
				release_requested.emit()
			else:
				grapple_requested.emit(event.position, swipe, duration)


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0
