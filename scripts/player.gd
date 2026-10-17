extends CharacterBody3D
## The player has no walking. It only has gravity, a thrown hook and momentum.
## Throw: the swipe direction aims, the flick speed sets how hard the hook is
## thrown (Pokémon GO style). The hook flies on an arc; where it hits, it
## sticks and the rope pulls the player in until the next throw.

enum HookState { IDLE, FLYING, ATTACHED }

## The hook does not stick to surfaces facing up more than this (floors).
const FLOOR_NORMAL_Y := 0.7

# --- Tuning (exposed in the inspector, change freely while playing) -----------
@export_group("Physics")
@export var gravity := 22.0
@export var max_speed := 50.0

@export_group("Throw")
## Hook speed (m/s) per finger speed (px/s, 720 px wide screen).
@export var throw_speed_per_px := 0.015
@export var hook_min_speed := 8.0
@export var hook_max_speed := 70.0
## Gravity on the flying hook. Higher = weak throws drop sooner.
@export var hook_gravity := 25.0
## Angle above the horizon for a straight-up swipe (degrees).
@export var throw_pitch := 50.0
## How strongly sideways swipes turn the throw toward the walls.
@export var throw_yaw_gain := 1.0

@export_group("Rope")
## The hook gives up when it gets further away than this.
@export var max_rope_length := 45.0
## The rope shortens by this much per second while attached (the pull).
@export var reel_speed := 10.0
@export var min_rope_length := 0.5
## Extra acceleration toward the anchor; makes the pull feel heavier.
@export var tension_boost := 6.0
## Touching a wall or the ceiling while attached lets go of the rope.
@export var release_on_contact := true
## No contact release right after the hook sticks (s), so a throw from a wall
## still pulls.
@export var contact_release_grace := 0.15

# --- State ---------------------------------------------------------------------
var hook_state := HookState.IDLE
## Hook position while it flies, anchor point once it sticks.
var anchor := Vector3.ZERO
var rope_length := 0.0
var _hook_velocity := Vector3.ZERO
var _attached_time := 0.0

@onready var rope := $Rope
@onready var hook: Node3D = $Hook
@onready var aim_line := $AimLine


func _ready() -> void:
	InputRouter.aim_changed.connect(_on_aim_changed)
	InputRouter.aim_cancelled.connect(_on_aim_cancelled)
	InputRouter.throw_requested.connect(throw_hook)
	InputRouter.release_requested.connect(release)
	hook.top_level = true
	hook.visible = false


func _physics_process(delta: float) -> void:
	velocity.y -= gravity * delta

	match hook_state:
		HookState.FLYING:
			_fly_hook(delta)
		HookState.ATTACHED:
			_attached_time += delta
			_apply_rope_constraint(delta)

	velocity = velocity.limit_length(max_speed)
	move_and_slide()

	if hook_state == HookState.ATTACHED and release_on_contact \
			and _attached_time >= contact_release_grace and _touches_wall_or_ceiling():
		release()

	if hook_state != HookState.IDLE:
		rope.update_line(_hook_origin(), anchor)
		hook.global_position = anchor


## Rope pull, applied as velocity so the momentum survives letting go.
## The player may move freely inside the rope sphere; leaving it is corrected
## by adding exactly the inward speed needed, which turns falling into swinging.
func _apply_rope_constraint(delta: float) -> void:
	rope_length = maxf(min_rope_length, rope_length - reel_speed * delta)

	var to_anchor := anchor - global_position
	var distance := to_anchor.length()
	if distance < 0.001:
		return
	var dir_to_anchor := to_anchor / distance

	velocity += dir_to_anchor * tension_boost * delta

	var inward_speed := velocity.dot(dir_to_anchor)
	var needed := (distance - rope_length) / delta
	if inward_speed < needed:
		velocity += dir_to_anchor * (needed - inward_speed)
	# Arrive at the anchor without overshooting it.
	var max_inward := maxf(0.0, distance - min_rope_length) / delta
	inward_speed = velocity.dot(dir_to_anchor)
	if inward_speed > max_inward:
		velocity -= dir_to_anchor * (inward_speed - max_inward)


func _fly_hook(delta: float) -> void:
	_hook_velocity.y -= hook_gravity * delta
	var next := anchor + _hook_velocity * delta
	var query := PhysicsRayQueryParameters3D.create(anchor, next)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		if hit.normal.y > FLOOR_NORMAL_Y:
			release()
			return
		anchor = hit.position
		rope_length = global_position.distance_to(anchor)
		hook_state = HookState.ATTACHED
		_attached_time = 0.0
	elif next.distance_to(global_position) > max_rope_length:
		release()
	else:
		anchor = next


func _touches_wall_or_ceiling() -> bool:
	for i in get_slide_collision_count():
		if get_slide_collision(i).get_normal().y <= FLOOR_NORMAL_Y:
			return true
	return false


## Screen swipe -> 3D throw direction. Straight up on screen throws forward
## (-Z) and up at throw_pitch; sideways swipes turn the throw toward the walls.
func _throw_direction(swipe: Vector2) -> Vector3:
	var s := Vector2(swipe.x, -swipe.y).normalized()
	var yaw := atan2(s.x, s.y) * throw_yaw_gain
	var pitch := deg_to_rad(throw_pitch)
	return Vector3(sin(yaw) * cos(pitch), sin(pitch), -cos(yaw) * cos(pitch))


## Downward swipes would throw backwards; they cancel instead.
func _is_valid_swipe(swipe: Vector2) -> bool:
	return -swipe.y > -0.25 * swipe.length()


func _hook_origin() -> Vector3:
	return global_position + Vector3(0.0, 0.6, 0.0)


func _on_aim_changed(swipe: Vector2) -> void:
	if not _is_valid_swipe(swipe):
		aim_line.visible = false
		return
	var from := _hook_origin()
	var to := from + _throw_direction(swipe) * max_rope_length
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		to = hit.position
	aim_line.update_line(from, to)
	aim_line.visible = true


func _on_aim_cancelled() -> void:
	aim_line.visible = false


func throw_hook(swipe: Vector2, flick_velocity: Vector2) -> void:
	aim_line.visible = false
	if not _is_valid_swipe(swipe):
		return
	var speed := clampf(flick_velocity.length() * throw_speed_per_px, hook_min_speed, hook_max_speed)
	release()
	anchor = _hook_origin()
	_hook_velocity = _throw_direction(swipe) * speed + velocity
	hook_state = HookState.FLYING
	rope.visible = true
	hook.visible = true


func release() -> void:
	hook_state = HookState.IDLE
	rope.visible = false
	hook.visible = false


func reset_to(position_3d: Vector3) -> void:
	release()
	aim_line.visible = false
	global_position = position_3d
	velocity = Vector3.ZERO
