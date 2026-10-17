extends Node3D
## Third-person camera behind the player, looking down the tunnel (-Z).
## The three "Spider-Man" ingredients live here: lag, look-ahead, speed FOV.

@export var target: Node3D
@export var offset := Vector3(0.0, 2.5, 7.0)
## Higher = snappier follow. Lower = more lag / more sense of speed.
@export var follow_speed := 6.0
@export var look_ahead := Vector3(0.0, 1.0, -8.0)
@export var base_fov := 75.0
@export var fov_per_speed := 0.5
@export var max_fov := 105.0
@export var fov_lerp_speed := 4.0

@onready var camera: Camera3D = $Camera3D


func _ready() -> void:
	if target:
		global_position = target.global_position + offset


func _physics_process(delta: float) -> void:
	if target == null:
		return

	var desired := target.global_position + offset
	global_position = global_position.lerp(desired, 1.0 - exp(-follow_speed * delta))
	camera.look_at(target.global_position + look_ahead, Vector3.UP)

	var speed := 0.0
	if target is CharacterBody3D:
		speed = (target as CharacterBody3D).velocity.length()
	var target_fov := clampf(base_fov + speed * fov_per_speed, base_fov, max_fov)
	camera.fov = lerpf(camera.fov, target_fov, 1.0 - exp(-fov_lerp_speed * delta))
