class_name RopeVisual
extends RefCounted
## One rope as drawn: a verlet chain from the hand to the hook, plus the hook
## mesh and the short animation of the hook flying back. The player has two:
## the attached rope and the hook in flight.
## With slack 1 the rope is taut and straight; more slack lets it sag (hook
## still flying) or snake (hook flying back). Purely visual.

## Points along the rope (segments + 1).
const SEGMENTS := 14
const GRAVITY := 22.0
## Velocity kept per step: the rope settles instead of swinging forever.
const DAMPING := 0.94
const ITERATIONS := 8
## Wave speed of the twang (rad/s).
const PLUCK_FREQUENCY := 55.0

var line: MeshInstance3D
var hook: Node3D
## Current points of the chain (world space).
var points := PackedVector3Array()
var _previous := PackedVector3Array()
var _retract_left := 0.0
var _retract_time := 0.2
var _retract_from := Vector3.ZERO
## Twang after the hook bites: current wave height (m), its decay and phase.
var _pluck := 0.0
var _pluck_decay := 9.0
var _pluck_phase := 0.0


func _init(line_node: MeshInstance3D, hook_node: Node3D) -> void:
	line = line_node
	hook = hook_node
	hook.top_level = true
	for node: Node3D in [line, hook]:
		node.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	hide()


## Draws the rope from origin to the hook. delta advances the chain (0 =
## one 60 Hz step); slack >= 1 is the rope length per straight distance.
func show_at(origin: Vector3, hook_position: Vector3, delta := 0.0, slack := 1.0) -> void:
	_retract_left = 0.0
	line.visible = true
	hook.visible = true
	hook.global_position = hook_position
	_simulate(origin, hook_position, delta, slack)
	_draw()


## Starts the twang: a standing wave of this height that dies down.
func pluck(height: float, decay: float) -> void:
	_pluck = height
	_pluck_decay = decay
	_pluck_phase = 0.0


func is_plucked() -> bool:
	return _pluck >= 0.01


## Lowest sag below the straight line between the ends (m), for tests.
func sag() -> float:
	if points.size() < 2:
		return 0.0
	var a := points[0]
	var b := points[-1]
	var most := 0.0
	for i in points.size():
		var t := float(i) / (points.size() - 1)
		most = maxf(most, a.lerp(b, t).y - points[i].y)
	return most


func hide() -> void:
	_retract_left = 0.0
	_pluck = 0.0
	points.clear()
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


## Call every rendered frame while retracting: the hook comes back, the
## rope goes slack and snakes after it.
func update_retract(delta: float, origin: Vector3) -> void:
	if _retract_left <= 0.0:
		return
	_retract_left = maxf(0.0, _retract_left - delta)
	var pos := _retract_from.lerp(origin, 1.0 - _retract_left / _retract_time)
	hook.global_position = pos
	_simulate(origin, pos, delta, 1.4)
	_draw()
	if _retract_left <= 0.0:
		hide()


func _simulate(a: Vector3, b: Vector3, delta: float, slack: float) -> void:
	var count := SEGMENTS + 1
	# New rope, or the ends jumped (teleport, new anchor): start straight.
	if points.size() != count or points[0].distance_to(a) > 8.0 or points[-1].distance_to(b) > 8.0:
		points.resize(count)
		_previous.resize(count)
		for i in count:
			points[i] = a.lerp(b, float(i) / SEGMENTS)
			_previous[i] = points[i]
	var dt := clampf(delta if delta > 0.0 else 1.0 / 60.0, 0.001, 1.0 / 30.0)
	for i in range(1, count - 1):
		var current := points[i]
		var moved := (current - _previous[i]) * DAMPING
		_previous[i] = current
		points[i] = current + moved + Vector3.DOWN * GRAVITY * dt * dt
	var rest := a.distance_to(b) * maxf(slack, 1.0) / SEGMENTS
	for iteration in ITERATIONS:
		points[0] = a
		points[count - 1] = b
		for i in range(count - 1):
			var d := points[i + 1] - points[i]
			var length := d.length()
			if length < 0.0001 or length <= rest:
				continue
			var correction := d * (1.0 - rest / length)
			# Pinned ends stay put, the free side moves all the way.
			if i == 0:
				points[i + 1] -= correction
			elif i + 1 == count - 1:
				points[i] += correction
			else:
				points[i] += correction * 0.5
				points[i + 1] -= correction * 0.5
	points[0] = a
	points[count - 1] = b
	if _pluck >= 0.01:
		_pluck *= exp(-_pluck_decay * dt)
		_pluck_phase += PLUCK_FREQUENCY * dt


func _draw() -> void:
	if _pluck < 0.01:
		line.update_points(points)
		return
	# Twang: two standing waves at right angles on top of the chain.
	var a := points[0]
	var b := points[-1]
	var dir := (b - a).normalized()
	var side := dir.cross(Vector3.UP)
	if side.length_squared() < 0.001:
		side = dir.cross(Vector3.RIGHT)
	side = side.normalized()
	var up := side.cross(dir)
	var shaken := PackedVector3Array()
	for i in points.size():
		var t := float(i) / (points.size() - 1)
		var wave := sin(PI * t) * _pluck
		shaken.append(points[i] + side * wave * sin(_pluck_phase) + up * wave * 0.5 * sin(_pluck_phase * 1.7 + 1.0))
	line.update_points(shaken)
