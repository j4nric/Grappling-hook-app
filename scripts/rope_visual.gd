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
## Twang after the hook bites: current wave height (m), its decay and phase.
var _pluck := 0.0
var _pluck_decay := 9.0
var _pluck_phase := 0.0

## Points along the rope while it twangs.
const PLUCK_SEGMENTS := 10
## Wave speed of the twang (rad/s).
const PLUCK_FREQUENCY := 55.0


func _init(line_node: MeshInstance3D, hook_node: Node3D) -> void:
	line = line_node
	hook = hook_node
	hook.top_level = true
	for node: Node3D in [line, hook]:
		node.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	hide()


## Draws the rope; delta advances the twang (0 = still).
func show_at(origin: Vector3, hook_position: Vector3, delta := 0.0) -> void:
	_retract_left = 0.0
	line.visible = true
	hook.visible = true
	hook.global_position = hook_position
	if _pluck < 0.01:
		line.update_line(origin, hook_position)
		return
	_pluck *= exp(-_pluck_decay * delta)
	_pluck_phase += PLUCK_FREQUENCY * delta
	line.update_points(_plucked_points(origin, hook_position))


## Starts the twang: a standing wave of this height that dies down.
func pluck(height: float, decay: float) -> void:
	_pluck = height
	_pluck_decay = decay
	_pluck_phase = 0.0


func is_plucked() -> bool:
	return _pluck >= 0.01


func _plucked_points(a: Vector3, b: Vector3) -> PackedVector3Array:
	var dir := (b - a).normalized()
	var side := dir.cross(Vector3.UP)
	if side.length_squared() < 0.001:
		side = dir.cross(Vector3.RIGHT)
	side = side.normalized()
	var up := side.cross(dir)
	var points := PackedVector3Array()
	for i in PLUCK_SEGMENTS + 1:
		var t := float(i) / PLUCK_SEGMENTS
		# Two standing waves at right angles: the rope shivers, not just swings.
		var wave := sin(PI * t) * _pluck
		var offset := side * wave * sin(_pluck_phase) + up * wave * 0.5 * sin(_pluck_phase * 1.7 + 1.0)
		points.append(a.lerp(b, t) + offset)
	return points


func hide() -> void:
	_retract_left = 0.0
	_pluck = 0.0
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
