extends Node3D
## Visual juice driven by player signals: sparks where the hook bites, a short
## hit-stop, dust on hard landings and wall scrapes, a burst at the zip launch,
## a trail and wind streaks at high speed.

@export var player: CharacterBody3D
## Speed (m/s) above which the speed trail shows.
@export var trail_speed := 18.0
## 1 = short vibration when the hook bites (native apps and Android browsers;
## iOS Safari has no vibration). A float so it works as a tuning slider.
@export var haptics := 1.0

@export_group("Hit-stop")
## Near-freeze when the hook bites (real seconds, 0 = off). The run timer
## does not count it.
@export var hit_stop_time := 0.05
## Game speed during the hit-stop.
@export var hit_stop_scale := 0.05
## Only hooks that bite while moving at least this fast (m/s) freeze;
## a calm first throw from the floor stays fluid.
@export var hit_stop_min_speed := 12.0

@export_group("Wind")
## Speed (m/s) at which wind streaks start, and where they are densest.
@export var streak_speed := 22.0
@export var streak_full_speed := 45.0

var _sparks: CPUParticles3D
var _dust: CPUParticles3D
var _burst: CPUParticles3D
var _trail: CPUParticles3D
var _streaks: CPUParticles3D
var _streak_material: StandardMaterial3D


func _ready() -> void:
	_sparks = _make_burst(Color(1.0, 0.85, 0.3), 18, 7.0, 0.35)
	_dust = _make_burst(Color(0.6, 0.55, 0.5), 14, 3.0, 0.5)
	_burst = _make_burst(Color(0.9, 0.95, 1.0), 12, 5.0, 0.3)
	_trail = _make_particles(Color(0.9, 0.9, 1.0, 0.8), 24, 0.35)
	_trail.emitting = false
	_trail.initial_velocity_max = 0.5
	_streaks = _make_streaks()
	player.hook_attached.connect(func(point: Vector3, normal: Vector3) -> void:
		_emit(_sparks, point, normal)
		if player.velocity.length() >= hit_stop_min_speed:
			TimeScale.hit_stop(hit_stop_time, hit_stop_scale)
		if haptics >= 0.5:
			Input.vibrate_handheld(25))
	player.deflected.connect(func(_speed: float) -> void:
		_emit(_dust, player.global_position, -player.velocity.normalized()))
	player.landed.connect(func(speed: float) -> void:
		if speed > 8.0:
			_emit(_dust, player.global_position + Vector3.DOWN * 0.8, Vector3.UP))
	player.rope_released.connect(func(reason: String) -> void:
		if reason == "zip":
			_emit(_burst, player.global_position, -player.velocity.normalized()))


func _physics_process(_delta: float) -> void:
	var speed := player.velocity.length()
	_trail.global_position = player.global_position
	_trail.emitting = speed > trail_speed
	# Streaks spawn in a box ahead of the player and drift backwards along the
	# flight direction, so the player flies through them.
	_streaks.emitting = speed > streak_speed
	if _streaks.emitting:
		var dir := player.velocity / speed
		_streaks.global_position = player.global_position + dir * 6.0
		_streaks.direction = -dir
		var strength := clampf((speed - streak_speed) / (streak_full_speed - streak_speed), 0.15, 1.0)
		_streak_material.albedo_color.a = 0.4 * strength


func _make_streaks() -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = 48
	p.lifetime = 0.35
	p.local_coords = false
	p.emitting = false
	p.gravity = Vector3.ZERO
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(5, 4, 3)
	p.spread = 0.0
	p.initial_velocity_min = 6.0
	p.initial_velocity_max = 10.0
	p.particle_flag_align_y = true
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.85, 0.9, 1.0, 0.35)
	_streak_material = mat
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.03, 1.4, 0.03)
	mesh.material = mat
	p.mesh = mesh
	add_child(p)
	return p


func _emit(particles: CPUParticles3D, at: Vector3, normal: Vector3) -> void:
	particles.global_position = at
	if not normal.is_zero_approx():
		particles.direction = normal
	particles.restart()


func _make_burst(color: Color, amount: int, speed: float, lifetime: float) -> CPUParticles3D:
	var p := _make_particles(color, amount, lifetime)
	p.one_shot = true
	p.explosiveness = 1.0
	p.emitting = false
	p.spread = 60.0
	p.initial_velocity_min = speed * 0.5
	p.initial_velocity_max = speed
	p.gravity = Vector3(0, -15, 0)
	return p


func _make_particles(color: Color, amount: int, lifetime: float) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = amount
	p.lifetime = lifetime
	p.local_coords = false
	p.gravity = Vector3.ZERO
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	if color.a < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var mesh := BoxMesh.new()
	mesh.size = Vector3.ONE * 0.12
	mesh.material = mat
	p.mesh = mesh
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.2
	add_child(p)
	return p
