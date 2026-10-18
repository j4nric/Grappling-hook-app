class_name Updraft
extends Area3D
## A column of rising air: inside it, bodies with a velocity (the player) are
## pushed up, up to a top speed. Wisps rise inside to show it.

## Upward acceleration inside (m/s²) on top of cancelling the body's own
## gravity, so it lifts the same whatever the gravity is tuned to.
@export var lift := 24.0
## Fastest upward speed it pushes to (m/s).
@export var max_rise := 20.0

var _bodies: Array[Node3D] = []


func _ready() -> void:
	add_to_group("updraft")
	body_entered.connect(func(body: Node3D) -> void:
		if "velocity" in body and body not in _bodies:
			_bodies.append(body))
	body_exited.connect(func(body: Node3D) -> void: _bodies.erase(body))


func _physics_process(delta: float) -> void:
	for body in _bodies:
		if is_instance_valid(body) and body.velocity.y < max_rise:
			var gravity: float = body.get("gravity") if "gravity" in body else 0.0
			body.velocity.y = minf(body.velocity.y + (gravity + lift) * delta, max_rise)


func contains(body: Node3D) -> bool:
	return body in _bodies
