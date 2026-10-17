extends AnimatableBody3D
## Moving obstacle: swings back and forth between its start position and
## start + travel. Holds the hook unless it is in the group "no_hook".

@export var travel := Vector3(8, 0, 0)
## Seconds for one full back-and-forth.
@export var period := 3.0
## Offset into the cycle (0..1), so movers in a row are not in sync.
@export var phase := 0.0

var _origin := Vector3.ZERO
var _time := 0.0


func _ready() -> void:
	_origin = position
	_time = phase * period


func _physics_process(delta: float) -> void:
	_time += delta
	var t := 0.5 - 0.5 * cos(TAU * _time / period)
	position = _origin + travel * t
