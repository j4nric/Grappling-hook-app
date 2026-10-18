class_name RopeVisual
extends RefCounted
## One rope as drawn: the line from the hand to the hook and the hook mesh,
## plus the short animation of the hook flying back. The player has two: the
## attached rope and the hook in flight.

var line: MeshInstance3D
var hook: Node3D
var _retract_left := 0.0
var _retract_time := 0.2
var _retract_from := Vector3.ZERO


func _init(line_node: MeshInstance3D, hook_node: Node3D) -> void:
	line = line_node
	hook = hook_node
	hook.top_level = true
	for node: Node3D in [line, hook]:
		node.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	hide()


func show_at(origin: Vector3, hook_position: Vector3) -> void:
	_retract_left = 0.0
	line.visible = true
	hook.visible = true
	line.update_line(origin, hook_position)
	hook.global_position = hook_position


func hide() -> void:
	_retract_left = 0.0
	line.visible = false
	hook.visible = false


## The hook flies back from `from` to the hand within `time` seconds.
func retract(from: Vector3, time: float) -> void:
	_retract_from = from
	_retract_time = maxf(time, 0.001)
	_retract_left = _retract_time
	line.visible = time > 0.0
	hook.visible = time > 0.0


func is_retracting() -> bool:
	return _retract_left > 0.0


## Call every rendered frame while retracting.
func update_retract(delta: float, origin: Vector3) -> void:
	if _retract_left <= 0.0:
		return
	_retract_left = maxf(0.0, _retract_left - delta)
	var pos := _retract_from.lerp(origin, 1.0 - _retract_left / _retract_time)
	line.update_line(origin, pos)
	hook.global_position = pos
	if _retract_left <= 0.0:
		hide()
