extends Node3D
## Visual juice driven by player signals: sparks where the hook bites, a short
## hit-stop, dust on hard landings and wall scrapes, a burst at the zip launch,
## a trail and wind streaks at high speed, and floating motes whose kind
## follows the hall (dust, embers over lava, snow in ice halls, fireflies in
## the dark, pale pollen under an open sky).

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

@export_group("Dust")
## Floating dust motes around the player: scale and stillness of the cave.
@export var dust_amount := 60

## Physics ticks the warm-up stays drawn (behind the black of the start).
const WARM_TICKS := 4

## Motes per kind of air: [color, gravity (m/s², + rises), top speed (m/s), size].
const AIR := {
	"dust": [Color(1.0, 0.85, 0.6, 0.5), -0.02, 0.3, 1.0],
	"embers": [Color(1.0, 0.45, 0.12, 0.95), 0.6, 1.2, 1.3],
	"snow": [Color(0.9, 0.95, 1.0, 0.8), -0.5, 0.4, 1.5],
	"fireflies": [Color(0.75, 1.0, 0.35, 1.0), 0.0, 0.9, 1.9],
	"pollen": [Color(0.7, 0.85, 1.0, 0.6), 0.12, 0.4, 1.1],
}

@export_group("Wind")
## Speed (m/s) at which wind streaks start, and where they are densest.
@export var streak_speed := 34.0
@export var streak_full_speed := 45.0

var _sparks: CPUParticles3D
var _dust: CPUParticles3D
var _burst: CPUParticles3D
var _trail: CPUParticles3D
var _streaks: CPUParticles3D
var _streak_material: StandardMaterial3D
var _motes: CPUParticles3D
## Kind of motes in the air now (AIR) and ticks until the next look.
var air := "dust"
var _air_check := 0
var _gold: CPUParticles3D
## Shader warm-up (warm_up()): physics ticks left, and the stand-in meshes.
var _warming := 0
var _warm_meshes: Node3D
var _spores: CPUParticles3D


func _ready() -> void:
	_sparks = _make_burst(Color(1.0, 0.85, 0.3), 18, 7.0, 0.35)
	_dust = _make_burst(Color(0.6, 0.55, 0.5), 14, 3.0, 0.5)
	_burst = _make_burst(Color(0.9, 0.95, 1.0), 12, 5.0, 0.3)
	_gold = _make_burst(Color(1.0, 0.78, 0.2), 32, 9.0, 0.55)
	_spores = _make_burst(Color(0.45, 1.0, 0.8), 26, 6.0, 0.8)
	_trail = _make_particles(Color(0.8, 0.9, 1.0, 0.6), 24, 0.35)
	_trail.emitting = false
	_trail.initial_velocity_max = 0.5
	_soften(_trail)
	_streaks = _make_streaks()
	_motes = _make_motes()
	player.hook_attached.connect(func(point: Vector3, normal: Vector3) -> void:
		_emit(_sparks, point, normal)
		if player.velocity.length() >= hit_stop_min_speed:
			TimeScale.hit_stop(hit_stop_time, hit_stop_scale)
		if haptics >= 0.5:
			Input.vibrate_handheld(25))
	player.perfect_chain.connect(func() -> void:
		_emit(_gold, player.global_position, -player.velocity.normalized())
		if haptics >= 0.5:
			Input.vibrate_handheld(40))
	player.bounced.connect(func() -> void:
		_emit(_spores, player.global_position + Vector3.DOWN * 0.8, Vector3.UP))
	player.deflected.connect(func(_speed: float) -> void:
		_emit(_dust, player.global_position, -player.velocity.normalized()))
	player.landed.connect(func(speed: float) -> void:
		if speed > 8.0:
			_emit(_dust, player.global_position + Vector3.DOWN * 0.8, Vector3.UP))
	player.rope_released.connect(func(reason: String) -> void:
		if reason == "zip":
			_emit(_burst, player.global_position, -player.velocity.normalized()))


func _physics_process(_delta: float) -> void:
	if _warming > 0:
		_warming -= 1
		if _warming == 0:
			_end_warm_up()
		return
	_air_check -= 1
	if _air_check <= 0:
		_air_check = 30
		var level: Level = get_parent().get("level") if get_parent() else null
		if level:
			set_air(air_for(level.hall_at(player.global_position.z)))
	var speed := player.velocity.length()
	_motes.global_position = player.global_position + Vector3(0, 2, -6)
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


## Browsers compile a shader the first time something with it is drawn,
## which stalls that frame: the first spark, zip burst, bounce, the first
## waterfall. At the start, while the screen is still black, every effect
## fires once and every level material is drawn once just in front of the
## player; a few ticks later they are hidden again.
func warm_up() -> void:
	var at := player.global_position + Vector3(0, 1.5, -3.0)
	for p: CPUParticles3D in _bursts():
		p.visible = true
		_emit(p, at, Vector3.UP)
	for p: CPUParticles3D in [_trail, _streaks]:
		p.global_position = at
		p.emitting = true
	_warm_meshes = Node3D.new()
	_warm_meshes.top_level = true
	add_child(_warm_meshes)
	var materials: Array[Material] = []
	materials.assign(CavernBuilder.MATERIALS.values())
	for shader: Shader in [CavernBuilder.WATERFALL_SHADER, CavernBuilder.SKY_SHADER]:
		var material := ShaderMaterial.new()
		material.shader = shader
		material.set_shader_parameter("noise", CavernBuilder.NOISE_TEXTURE)
		materials.append(material)
	for i in materials.size():
		var mesh := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3.ONE * 0.05
		box.material = materials[i]
		mesh.mesh = box
		mesh.position = at + Vector3((i - materials.size() / 2.0) * 0.06, 0, 0)
		_warm_meshes.add_child(mesh)
	_warming = WARM_TICKS


func _end_warm_up() -> void:
	for p: CPUParticles3D in _bursts():
		p.visible = false
	_trail.emitting = false
	_streaks.emitting = false
	if _warm_meshes:
		_warm_meshes.queue_free()
		_warm_meshes = null


func is_warming_up() -> bool:
	return _warming > 0


func _bursts() -> Array[CPUParticles3D]:
	return [_sparks, _dust, _burst, _gold, _spores]


## The kind of air in a hall (CavernBuilder segment).
static func air_for(hall: Dictionary) -> String:
	if hall.is_empty():
		return "dust"
	if hall.floor == "lava":
		return "embers"
	if hall.dark:
		return "fireflies"
	if float(hall.ice) >= 0.5 or hall.ice_stalactites:
		return "snow"
	if hall.open:
		return "pollen"
	return "dust"


func set_air(kind: String) -> void:
	if kind == air or not AIR.has(kind):
		return
	air = kind
	var look: Array = AIR[kind]
	_motes.color = look[0]
	_motes.gravity = Vector3(0, look[1], 0)
	_motes.initial_velocity_max = look[2]
	_motes.scale_amount_min = 0.5 * float(look[3])
	_motes.scale_amount_max = 1.2 * float(look[3])


## Soft glowing dots instead of boxes.
func _soften(p: CPUParticles3D) -> void:
	var mat: StandardMaterial3D = (p.mesh as BoxMesh).material
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.albedo_texture = preload("res://assets/textures/dust.png")
	var quad := QuadMesh.new()
	quad.size = Vector2(0.35, 0.35)
	quad.material = mat
	p.mesh = quad


func _make_motes() -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = dust_amount
	p.lifetime = 6.0
	p.preprocess = 6.0
	p.local_coords = false
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(10, 7, 14)
	p.color = AIR["dust"][0]
	p.direction = Vector3(0.3, 0.2, 0.1)
	p.spread = 180.0
	p.initial_velocity_min = 0.05
	p.initial_velocity_max = 0.3
	p.gravity = Vector3(0, -0.02, 0)
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.2
	# Fade in and out instead of popping.
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 0))
	fade.set_color(1, Color(1, 1, 1, 0))
	fade.add_point(0.25, Color(1, 1, 1, 1))
	fade.add_point(0.75, Color(1, 1, 1, 1))
	p.color_ramp = fade
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.vertex_color_use_as_albedo = true
	mat.albedo_texture = preload("res://assets/textures/dust.png")
	# Right in front of the camera a mote would be a big blob: fade it out.
	mat.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_PIXEL_ALPHA
	mat.distance_fade_min_distance = 1.5
	mat.distance_fade_max_distance = 5.0
	var mesh := QuadMesh.new()
	mesh.size = Vector2(0.12, 0.12)
	mesh.material = mat
	p.mesh = mesh
	add_child(p)
	return p


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
	particles.visible = true
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
