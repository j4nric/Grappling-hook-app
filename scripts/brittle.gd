class_name Brittle
extends AnimatableBody3D
## A brittle stalactite: it holds the hook for a moment, shakes, then breaks
## and falls into the depth. Rebuilt when the run restarts.

signal broken

## Seconds it holds after the hook bites.
@export var hold_time := 0.8
## How far it shakes while cracking (m).
@export var shake := 0.08

var is_broken := false
var _home := Transform3D.IDENTITY
var _left := -1.0
var _fall_speed := 0.0


func _ready() -> void:
	add_to_group("brittle")
	_home = transform


## The hook bit: start cracking.
func hooked() -> void:
	if not is_broken and _left < 0.0:
		_left = hold_time


func is_cracking() -> bool:
	return _left >= 0.0 and not is_broken


## Whole again (restart).
func restore() -> void:
	is_broken = false
	_left = -1.0
	_fall_speed = 0.0
	transform = _home
	visible = true
	for shape in find_children("*", "CollisionShape3D", false, false):
		(shape as CollisionShape3D).disabled = false


func _physics_process(delta: float) -> void:
	if is_broken:
		# Falls away and is gone once deep in the fog.
		_fall_speed += 22.0 * delta
		position.y -= _fall_speed * delta
		if position.y < _home.origin.y - 80.0:
			visible = false
			set_physics_process(false)
		return
	if _left < 0.0:
		return
	_left -= delta
	var t := 1.0 - _left / hold_time
	transform.origin = _home.origin + Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)) * shake * t
	if _left <= 0.0:
		is_broken = true
		for shape in find_children("*", "CollisionShape3D", false, false):
			(shape as CollisionShape3D).set_deferred("disabled", true)
		broken.emit()
