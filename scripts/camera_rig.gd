extends Node3D
## Third-person camera behind the player, looking down the tunnel (-Z).
## The "Spider-Man" ingredients live here: lag, look-ahead (also toward the
## hook), speed FOV, roll when swinging sideways and shake on impacts.

@export var target: Node3D
## Camera that actually renders (inside the low-res pixel viewport). It copies
## this rig's camera every frame.
@export var view_camera: Camera3D
@export var offset := Vector3(0.0, 3.5, 10.0)
## Higher = snappier follow. Lower = more lag / more sense of speed.
@export var follow_speed := 6.0
@export var look_ahead := Vector3(0.0, 3.0, -12.0)

## The camera never goes behind walls: it moves in front of whatever is
## between it and the player, keeping this gap (m).
@export var collision_margin := 0.5
## How fast it backs out again once the wall is gone (1/s); moving in is instant.
@export var collision_return_speed := 4.0

@export_group("Framing")
## Under a ceiling closer than this (m) above the player, the camera drops
## and looks up, so the hall stays in view instead of the rock overhead.
@export var ceiling_near := 7.0
## Camera height offset (m) and extra look height right under the ceiling.
@export var ceiling_offset_y := -1.0
@export var ceiling_look_up := 4.0
## Finish: the camera circles the player this fast (rad/s) at this distance.
@export var orbit_speed := 0.9
@export var orbit_distance := 8.0

@export_group("Field of view")
## The FOV is horizontal, so the tunnel width stays visible in portrait.
@export var keep_width := true
@export var base_fov := 65.0
@export var fov_per_speed := 0.4
@export var max_fov := 90.0
@export var fov_lerp_speed := 4.0
## Extra FOV (degrees) for a moment at the zip launch: the punch of the launch.
@export var zip_fov_kick := 12.0
## How fast that kick fades (1/s).
@export var fov_kick_decay := 5.0

@export_group("Hook")
## How far the view turns toward the anchor while the rope pulls (0..1).
@export var anchor_look_weight := 0.3
@export var look_lerp_speed := 5.0

@export_group("Roll")
## Degrees of roll per m/s of sideways speed.
@export var roll_per_speed := 1.2
@export var max_roll := 12.0
@export var roll_lerp_speed := 4.0

@export_group("Shake")
## Maximum shake offset (m) at full trauma.
@export var shake_strength := 0.35
## Trauma added when the hook sticks (0..1).
@export var hook_shake := 0.35
## Trauma per m/s of landing speed above 8 m/s.
@export var landing_shake_per_speed := 0.04
## Trauma lost per second.
@export var shake_decay := 2.5

var _look_target := Vector3.ZERO
var _roll := 0.0
## 0..1; the shake grows with its square.
var _trauma := 0.0
## Current extra FOV from a zip launch (degrees).
var _fov_kick := 0.0
## FOV from speed alone, without the kick.
var _fov_base := 65.0
## Camera position without collision (smoothed follow).
var _follow := Vector3.ZERO
## 0..1: how close the ceiling is above the player (smoothed).
var ceiling_factor := 0.0
## Finish orbit: on, and its angle.
var orbiting := false
var _orbit_angle := 0.0
## Camera offset from the player after wall clipping (smoothed outward).
var _clip_offset := Vector3.ZERO
## True while clipped or still backing out to the free position.
var _returning := false

@onready var camera: Camera3D = $Camera3D


func _ready() -> void:
	camera.keep_aspect = Camera3D.KEEP_WIDTH if keep_width else Camera3D.KEEP_HEIGHT
	# The rig follows the interpolated player every rendered frame itself.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	if view_camera:
		view_camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	camera.fov = base_fov
	_fov_base = base_fov
	if target:
		global_position = target.global_position + offset
		_follow = global_position
		_look_target = target.global_position + look_ahead
		if target.has_signal("hook_attached"):
			target.hook_attached.connect(func(_p: Vector3, _n: Vector3) -> void: add_trauma(hook_shake))
		if target.has_signal("landed"):
			target.landed.connect(_on_landed)
		if target.has_signal("rope_released"):
			target.rope_released.connect(func(reason: String) -> void:
				if reason == "zip":
					kick_fov())


## The FOV punch of a zip launch or a speed ring.
func kick_fov() -> void:
	_fov_kick = zip_fov_kick


func add_trauma(amount: float) -> void:
	_trauma = clampf(_trauma + amount, 0.0, 1.0)


func _on_landed(impact_speed: float) -> void:
	add_trauma(maxf(0.0, impact_speed - 8.0) * landing_shake_per_speed)


## Runs per rendered frame on the interpolated player position: smooth at any
## refresh rate (the physics tick is fixed at 60 Hz).
func _process(delta: float) -> void:
	if target == null:
		return

	var target_position := target.get_global_transform_interpolated().origin
	ceiling_factor = lerpf(ceiling_factor, _ceiling_closeness(target_position), 1.0 - exp(-3.0 * delta))
	var frame_offset := offset
	frame_offset.y = lerpf(offset.y, ceiling_offset_y, ceiling_factor)
	if orbiting:
		_orbit_angle += orbit_speed * delta
		frame_offset = Vector3(sin(_orbit_angle), 0.25, cos(_orbit_angle)) * orbit_distance
	var desired := target_position + frame_offset
	_follow = _follow.lerp(desired, 1.0 - exp(-follow_speed * delta))
	global_position = _avoid_walls(target_position, _follow, delta)

	var look := target_position + look_ahead + Vector3.UP * ceiling_look_up * ceiling_factor
	if orbiting:
		look = target_position
	if _is_pulled():
		look = look.lerp(target.anchor, anchor_look_weight)
	_look_target = _look_target.lerp(look, 1.0 - exp(-look_lerp_speed * delta))

	var velocity := Vector3.ZERO
	if target is CharacterBody3D:
		velocity = (target as CharacterBody3D).velocity
	# Bank into the swing: moving right tilts the view right.
	var roll_target := clampf(velocity.x * roll_per_speed, -max_roll, max_roll)
	_roll = lerpf(_roll, roll_target, 1.0 - exp(-roll_lerp_speed * delta))

	_trauma = maxf(0.0, _trauma - shake_decay * delta)
	var shake := Vector3(randf_range(-1, 1), randf_range(-1, 1), 0.0) * shake_strength * _trauma * _trauma
	camera.position = shake
	camera.look_at(_look_target + shake, Vector3.UP.rotated(Vector3.FORWARD, deg_to_rad(_roll)))

	var target_fov := clampf(base_fov + velocity.length() * fov_per_speed, base_fov, max_fov)
	_fov_kick *= exp(-fov_kick_decay * delta)
	_fov_base = lerpf(_fov_base, target_fov, 1.0 - exp(-fov_lerp_speed * delta))
	camera.fov = minf(_fov_base + _fov_kick, max_fov + zip_fov_kick)

	if view_camera:
		view_camera.global_transform = camera.global_transform
		view_camera.fov = camera.fov
		view_camera.keep_aspect = camera.keep_aspect


## Finish shot: circle the player (until stop_orbit()).
func start_orbit() -> void:
	orbiting = true
	# Start from where the camera is now, behind the player.
	_orbit_angle = atan2(offset.x, offset.z)


func stop_orbit() -> void:
	orbiting = false


## 1 with rock right above the player, 0 with ceiling_near or more space.
func _ceiling_closeness(at: Vector3) -> float:
	if not is_inside_tree() or ceiling_near <= 0.0:
		return 0.0
	var query := PhysicsRayQueryParameters3D.create(at, at + Vector3.UP * ceiling_near)
	if target is CollisionObject3D:
		query.exclude = [(target as CollisionObject3D).get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return 0.0
	return clampf(1.0 - (at.distance_to(hit.position) - 1.0) / (ceiling_near - 1.0), 0.0, 1.0)


## Moves the camera in front of geometry between the player and it. Height
## and distance are clipped one after the other: under a low ceiling the
## camera drops down but stays behind the player instead of sliding into
## the player along the diagonal.
func _avoid_walls(target_position: Vector3, wanted: Vector3, delta: float) -> Vector3:
	if not is_inside_tree():
		return wanted
	var above := _clip(target_position, Vector3(target_position.x, wanted.y, target_position.z))
	var clipped := _clip(above, Vector3(wanted.x, above.y, wanted.z))
	var free_offset := wanted - target_position
	var offset_now := clipped - target_position
	var k := 1.0 - exp(-collision_return_speed * delta)
	if not offset_now.is_equal_approx(free_offset):
		# Blocked: in at once (never see through the wall), out smoothly.
		if not _returning or offset_now.length() < _clip_offset.length():
			_clip_offset = offset_now
		else:
			_clip_offset = _clip_offset.lerp(offset_now, k)
		_returning = true
	elif _returning:
		_clip_offset = _clip_offset.lerp(free_offset, k)
		if _clip_offset.distance_to(free_offset) < 0.05 or free_offset.length() < _clip_offset.length():
			_returning = false
	if not _returning:
		return wanted
	return target_position + _clip_offset


## The point on the way from `from` to `to` that keeps collision_margin from
## the first obstacle (or `to` itself).
func _clip(from: Vector3, to: Vector3) -> Vector3:
	var span := to - from
	var length := span.length()
	if length < 0.01:
		return to
	var dir := span / length
	var query := PhysicsRayQueryParameters3D.create(from, to + dir * collision_margin)
	if target is CollisionObject3D:
		query.exclude = [(target as CollisionObject3D).get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return to
	return from + dir * clampf(from.distance_to(hit.position) - collision_margin, 0.0, length)


func _is_pulled() -> bool:
	return "hook_state" in target and target.hook_state == target.HookState.ATTACHED
