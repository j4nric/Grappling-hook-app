class_name SpeedRing
extends Area3D
## A glowing ring in the air: flying through it fires the player forward
## (along the ring's -Z) to at least `boost_speed`. Recharges after a while.

signal passed(ring: SpeedRing)

## Speed (m/s) along the ring direction after passing.
@export var boost_speed := 44.0
## Seconds until the ring works again.
@export var recharge := 2.0

var _ready_in := 0.0


func _ready() -> void:
	add_to_group("speed_ring")
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_ready_in = maxf(0.0, _ready_in - delta)
	# Spins slowly; dims while recharging.
	rotate_object_local(Vector3.FORWARD, delta * 0.8)
	var glow := 0.25 if _ready_in > 0.0 else 1.0
	for mesh in find_children("*", "MeshInstance3D", false, false):
		(mesh as MeshInstance3D).transparency = 1.0 - glow


func _on_body_entered(body: Node3D) -> void:
	if _ready_in > 0.0 or not body.is_in_group("player"):
		return
	var forward := -global_basis.z.normalized()
	var along: float = body.velocity.dot(forward)
	if along < boost_speed:
		body.velocity += forward * (boost_speed - along)
	_ready_in = recharge
	passed.emit(self)
