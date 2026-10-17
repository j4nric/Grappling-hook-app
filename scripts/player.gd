extends CharacterBody3D
## The player has no walking. It only has gravity, a rope and momentum.
## Everything that makes the game feel good lives in _apply_rope_constraint().

# --- Tuning (exposed in the inspector, change freely while playing) -----------
@export_group("Physics")
@export var gravity := 22.0
@export var max_speed := 50.0

@export_group("Rope")
## Maximum distance at which a grapple attaches.
@export var max_rope_length := 45.0
## The rope shortens by this much per second while attached (gives "pull").
@export var reel_speed := 4.0
@export var min_rope_length := 3.0
## Small extra pull toward the anchor each frame; makes swings feel heavier.
@export var tension_boost := 2.0

# --- State ---------------------------------------------------------------------
var attached := false
var anchor := Vector3.ZERO
var rope_length := 0.0

@onready var rope := $Rope


func _ready() -> void:
	InputRouter.grapple_requested.connect(_on_grapple_requested)
	InputRouter.release_requested.connect(release)


func _physics_process(delta: float) -> void:
	velocity.y -= gravity * delta

	if attached:
		_apply_rope_constraint(delta)

	velocity = velocity.limit_length(max_speed)
	move_and_slide()

	if attached:
		rope.update_line(global_position, anchor)


## Pendulum constraint: the player may move freely, but never further than
## rope_length from the anchor. Velocity pointing away from the anchor is
## removed, which converts falling into swinging.
func _apply_rope_constraint(delta: float) -> void:
	rope_length = maxf(min_rope_length, rope_length - reel_speed * delta)

	var to_anchor := anchor - global_position
	var distance := to_anchor.length()
	if distance < 0.001:
		return
	var dir_to_anchor := to_anchor / distance

	if distance > rope_length:
		# Pull the body back onto the rope sphere.
		global_position = anchor - dir_to_anchor * rope_length
		# Kill the outward velocity component (keeps tangential swing).
		var outward := -dir_to_anchor
		var outward_speed := velocity.dot(outward)
		if outward_speed > 0.0:
			velocity -= outward * outward_speed

	velocity += dir_to_anchor * tension_boost * delta


func _on_grapple_requested(screen_pos: Vector2, _swipe: Vector2, _duration: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return

	var from := camera.project_ray_origin(screen_pos)
	var direction := camera.project_ray_normal(screen_pos)
	var query := PhysicsRayQueryParameters3D.create(from, from + direction * (max_rope_length * 2.0))
	query.exclude = [get_rid()]

	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return

	var length := global_position.distance_to(hit.position)
	if length > max_rope_length:
		return

	anchor = hit.position
	rope_length = length
	attached = true
	rope.visible = true


func release() -> void:
	attached = false
	rope.visible = false


func reset_to(position_3d: Vector3) -> void:
	release()
	global_position = position_3d
	velocity = Vector3.ZERO
