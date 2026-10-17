extends CharacterBody3D
## The player has no walking. It only has gravity, a thrown hook and momentum.
## Throw: the swipe direction aims, the flick speed sets how hard the hook is
## thrown (Pokémon GO style). The hook flies on an arc; where it hits, it
## sticks and the rope yanks the player toward it. Shortly before the anchor
## the rope lets go on its own and the player flies on with full speed
## ("zip launch").

signal hook_thrown
signal hook_attached(point: Vector3, normal: Vector3)
## The hook found nothing to stick to.
signal hook_missed
## reason: "zip", "contact", "blocked", "tap", "throw", "reset"
signal rope_released(reason: String)
signal landed(impact_speed: float)

enum HookState { IDLE, FLYING, ATTACHED }

## The hook does not stick to surfaces facing up more than this (floors).
const FLOOR_NORMAL_Y := 0.7

# --- Tuning (exposed in the inspector, change freely while playing) -----------
@export_group("Physics")
@export var gravity := 22.0
@export var max_speed := 50.0
## Braking on the floor (m/s²) when no rope pulls; stops endless sliding.
@export var floor_friction := 25.0

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
## Speed (m/s) toward the anchor added the moment the hook sticks: the yank.
@export var pull_impulse := 6.0
## The rope shortens this fast right after the hook sticks (m/s) ...
@export var reel_speed := 8.0
## ... and this much faster every second (m/s²) ...
@export var reel_acceleration := 30.0
## ... up to this speed (m/s).
@export var reel_max_speed := 30.0
@export var min_rope_length := 0.5
## Extra acceleration toward the anchor; makes the pull feel heavier.
@export var tension_boost := 6.0
## The rope lets go this far before the anchor and the player flies on with
## full speed (zip launch). 0 = pull all the way.
@export var zip_release_distance := 2.5
## Extra speed (m/s) in flight direction at the zip launch.
@export var zip_boost := 3.0
## Touching a wall or the ceiling while attached lets go of the rope.
@export var release_on_contact := true
## No contact or zip release right after the hook sticks (s), so a throw from
## close to a wall still pulls.
@export var contact_release_grace := 0.15
## Let go when level geometry gets between player and anchor.
@export var release_when_blocked := true

# --- State ---------------------------------------------------------------------
var hook_state := HookState.IDLE
## Hook position while it flies, anchor point once it sticks.
var anchor := Vector3.ZERO
var rope_length := 0.0
var _hook_velocity := Vector3.ZERO
var _attached_time := 0.0
var _was_on_floor := false

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

	if hook_state != HookState.ATTACHED and is_on_floor():
		_apply_floor_friction(delta)

	velocity = velocity.limit_length(max_speed)
	var fall_speed := -velocity.y
	move_and_slide()

	if is_on_floor() and not _was_on_floor:
		landed.emit(fall_speed)
	_was_on_floor = is_on_floor()

	if hook_state == HookState.ATTACHED and _attached_time >= contact_release_grace:
		if zip_release_distance > 0.0 and global_position.distance_to(anchor) <= zip_release_distance:
			_zip_launch()
		elif release_on_contact and _touches_wall_or_ceiling():
			release("contact")
		elif release_when_blocked and _is_rope_blocked():
			release("blocked")

	if hook_state != HookState.IDLE:
		rope.update_line(_hook_origin(), anchor)
		hook.global_position = anchor


## Rope pull, applied as velocity so the momentum survives letting go.
## The player may move freely inside the rope sphere; leaving it is corrected
## by adding exactly the inward speed needed, which turns falling into swinging.
## The reel starts at reel_speed and accelerates, so the pull builds up.
func _apply_rope_constraint(delta: float) -> void:
	var reel := minf(reel_speed + reel_acceleration * _attached_time, reel_max_speed)
	rope_length = maxf(min_rope_length, rope_length - reel * delta)

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


func _apply_floor_friction(delta: float) -> void:
	var flat := Vector2(velocity.x, velocity.z)
	flat = flat.move_toward(Vector2.ZERO, floor_friction * delta)
	velocity.x = flat.x
	velocity.z = flat.y


func _zip_launch() -> void:
	var speed := velocity.length()
	if speed > 0.001:
		velocity += velocity / speed * zip_boost
	release("zip")


## True when level geometry lies between the player and the anchor.
func _is_rope_blocked() -> bool:
	var from := _hook_origin()
	var query := PhysicsRayQueryParameters3D.create(from, anchor)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	# The anchor surface itself is not an obstacle.
	return not hit.is_empty() and hit.position.distance_to(anchor) > 0.3


## Sticks the hook at point and starts the pull.
func attach(point: Vector3, normal: Vector3) -> void:
	anchor = point
	rope_length = global_position.distance_to(anchor)
	hook_state = HookState.ATTACHED
	_attached_time = 0.0
	rope.visible = true
	hook.visible = true
	velocity += global_position.direction_to(anchor) * pull_impulse
	hook_attached.emit(point, normal)


func _fly_hook(delta: float) -> void:
	_hook_velocity.y -= hook_gravity * delta
	var next := anchor + _hook_velocity * delta
	var query := PhysicsRayQueryParameters3D.create(anchor, next)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		if hit.normal.y > FLOOR_NORMAL_Y:
			_miss()
			return
		attach(hit.position, hit.normal)
	elif next.distance_to(global_position) > max_rope_length:
		_miss()
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
	release("throw")
	anchor = _hook_origin()
	_hook_velocity = _throw_direction(swipe) * speed + velocity
	hook_state = HookState.FLYING
	rope.visible = true
	hook.visible = true
	hook_thrown.emit()


func _miss() -> void:
	_set_idle()
	hook_missed.emit()


## Lets go of the rope. Signals only if a rope or hook was out.
func release(reason := "tap") -> void:
	if hook_state == HookState.IDLE:
		return
	_set_idle()
	rope_released.emit(reason)


func _set_idle() -> void:
	hook_state = HookState.IDLE
	rope.visible = false
	hook.visible = false


func reset_to(position_3d: Vector3) -> void:
	release("reset")
	aim_line.visible = false
	global_position = position_3d
	velocity = Vector3.ZERO
