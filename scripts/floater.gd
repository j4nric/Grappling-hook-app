class_name Floater
extends AnimatableBody3D
## A floating stone in an open hall: hangs in the air and bobs gently. The
## hook holds on it and rides along (it is an AnimatableBody3D).

## Up and down by this much (m) ...
@export var bob := 0.6
## ... once every this many seconds.
@export var period := 5.0

var _base := Vector3.ZERO
var _time := 0.0


func _ready() -> void:
	add_to_group("floater")
	_base = position
	# Stones next to each other must not bob in sync.
	_time = fmod(absf(position.x * 1.7 + position.z * 0.9), period)


func _physics_process(delta: float) -> void:
	_time += delta
	position = _base + Vector3(0, sin(_time / period * TAU) * bob, 0)
