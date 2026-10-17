extends Node3D
## Visual juice driven by player signals: sparks where the hook bites, dust on
## hard landings, a burst at the zip launch and a trail at high speed.

@export var player: CharacterBody3D
## Speed (m/s) above which the speed trail shows.
@export var trail_speed := 18.0
## 1 = short vibration when the hook bites (native apps and Android browsers;
## iOS Safari has no vibration). A float so it works as a tuning slider.
@export var haptics := 1.0

var _sparks: CPUParticles3D
var _dust: CPUParticles3D
var _burst: CPUParticles3D
var _trail: CPUParticles3D


func _ready() -> void:
	_sparks = _make_burst(Color(1.0, 0.85, 0.3), 18, 7.0, 0.35)
	_dust = _make_burst(Color(0.6, 0.55, 0.5), 14, 3.0, 0.5)
	_burst = _make_burst(Color(0.9, 0.95, 1.0), 12, 5.0, 0.3)
	_trail = _make_particles(Color(0.9, 0.9, 1.0, 0.8), 24, 0.35)
	_trail.emitting = false
	_trail.initial_velocity_max = 0.5
	player.hook_attached.connect(func(point: Vector3, normal: Vector3) -> void:
		_emit(_sparks, point, normal)
		if haptics >= 0.5:
			Input.vibrate_handheld(25))
	player.landed.connect(func(speed: float) -> void:
		if speed > 8.0:
			_emit(_dust, player.global_position + Vector3.DOWN * 0.8, Vector3.UP))
	player.rope_released.connect(func(reason: String) -> void:
		if reason == "zip":
			_emit(_burst, player.global_position, -player.velocity.normalized()))


func _physics_process(_delta: float) -> void:
	_trail.global_position = player.global_position
	_trail.emitting = player.velocity.length() > trail_speed


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
