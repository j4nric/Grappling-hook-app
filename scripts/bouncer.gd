class_name Bouncer
extends Area3D
## A giant mushroom: coming down onto its cap throws the body up and on
## (forward along its flat movement, or down the cave). The cap squashes.
## Bodies with a bounce(velocity) method (the player) get the new velocity
## through it, so they can react (sound, somersault).

## Upward speed after the bounce (m/s).
@export var bounce_speed := 26.0
## Speed added along the flat movement (m/s).
@export var forward_boost := 8.0
## A body bounces at most once in this time (s).
@export var cooldown := 0.35

## The cap mesh that squashes on a bounce.
var cap: Node3D
var _cool := 0.0


func _ready() -> void:
	add_to_group("bouncer")


func _physics_process(delta: float) -> void:
	_cool -= delta
	if _cool > 0.0:
		return
	for body in get_overlapping_bodies():
		# Coming down or resting on the cap; not while still flying up.
		if "velocity" in body and body.velocity.y <= 1.0:
			bounce(body)
			return


func bounce(body: Node3D) -> void:
	_cool = cooldown
	var v: Vector3 = body.velocity
	var flat := Vector3(v.x, 0.0, v.z)
	var dir := flat.normalized() if flat.length() > 2.0 else Vector3.FORWARD
	var launched := flat + dir * forward_boost + Vector3.UP * bounce_speed
	if body.has_method("bounce"):
		body.bounce(launched)
	else:
		body.velocity = launched
	if cap:
		var tween := cap.create_tween()
		cap.scale = Vector3(1.25, 0.6, 1.25)
		tween.tween_property(cap, "scale", Vector3.ONE, 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
