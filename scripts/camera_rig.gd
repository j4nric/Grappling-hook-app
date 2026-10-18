extends Node3D
## Third-person camera behind the player, looking down the tunnel (-Z).
## The "Spider-Man" ingredients live here: lag, look-ahead (also toward the
## hook), speed FOV, roll when swinging sideways and shake on impacts.

@export var target: Node3D
## Camera that actually renders (inside the low-res pixel viewport). It copies
## this rig's camera every frame.
@export var view_camera: Camera3D
@export var offset := Vector3(0.0, 2.5, 7.0)
## Higher = snappier follow. Lower = more lag / more sense of speed.
@export var follow_speed := 6.0
@export var look_ahead := Vector3(0.0, 2.5, -8.0)

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
		_look_target = target.global_position + look_ahead
		if target.has_signal("hook_attached"):
			target.hook_attached.connect(func(_p: Vector3, _n: Vector3) -> void: add_trauma(hook_shake))
		if target.has_signal("landed"):
			target.landed.connect(_on_landed)
		if target.has_signal("rope_released"):
			target.rope_released.connect(func(reason: String) -> void:
				if reason == "zip":
					_fov_kick = zip_fov_kick)


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
	var desired := target_position + offset
	global_position = global_position.lerp(desired, 1.0 - exp(-follow_speed * delta))

	var look := target_position + look_ahead
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


func _is_pulled() -> bool:
	return "hook_state" in target and target.hook_state == target.HookState.ATTACHED
