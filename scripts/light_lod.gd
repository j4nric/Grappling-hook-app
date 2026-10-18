class_name LightLod
extends Node
## Keeps only the lights near the camera on. The caves have up to ~40 lights,
## but the Compatibility renderer (web) lights each object with at most 8 and
## every light costs time: far lights fade out, near ones fade in.

## Node whose position counts (the camera rig).
@export var camera: Node3D
## Lights on at most at the same time ...
@export var max_lights := 10
## ... and only within this distance (m).
@export var max_distance := 90.0
## How fast a light fades in or out (1/s).
@export var fade_speed := 4.0
## Seconds between re-sorting the lights.
@export var update_interval := 0.1

var _lights: Array[Light3D] = []
## Light -> target fade (0 or 1).
var _targets := {}
var _clock := 0.0


## Takes over the lights of a newly loaded level.
func track(root: Node) -> void:
	_lights.clear()
	_targets.clear()
	for node in root.find_children("*", "Light3D", true, false):
		var light := node as Light3D
		if not light.has_meta("lod_base"):
			light.set_meta("lod_base", light.light_energy)
		_lights.append(light)
		_set_fade(light, 0.0)
	_clock = update_interval
	_update_targets()
	# Start at the right state, no fade-in on load.
	for light in _lights:
		_set_fade(light, _targets.get(light, 0.0))


func active_count() -> int:
	var count := 0
	for light in _lights:
		if is_instance_valid(light) and light.visible:
			count += 1
	return count


func _process(delta: float) -> void:
	_clock += delta
	if _clock >= update_interval:
		_clock = 0.0
		_update_targets()
	var k := minf(1.0, fade_speed * delta)
	for light in _lights:
		if not is_instance_valid(light):
			continue
		var current := _fade_of(light)
		var target: float = _targets.get(light, 0.0)
		if not is_equal_approx(current, target):
			_set_fade(light, move_toward(current, target, k))


func _update_targets() -> void:
	if camera == null or _lights.is_empty():
		return
	var origin := camera.global_position
	var near: Array = []
	for light in _lights:
		if not is_instance_valid(light) or not light.is_inside_tree():
			continue
		var d := light.global_position.distance_to(origin)
		if d <= max_distance:
			near.append([d, light])
	near.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	_targets.clear()
	for i in mini(max_lights, near.size()):
		_targets[near[i][1]] = 1.0


func _fade_of(light: Light3D) -> float:
	return light.get_meta("lod_fade", 1.0)


func _set_fade(light: Light3D, value: float) -> void:
	light.set_meta("lod_fade", value)
	light.visible = value > 0.001
	if "fade" in light:
		light.fade = value
	else:
		light.light_energy = float(light.get_meta("lod_base")) * value
