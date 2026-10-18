class_name VerletBand
extends MeshInstance3D
## A scarf: a short verlet chain hanging from a moving point, drawn as a flat
## two-sided ribbon. It trails behind with the player's speed and flutters.

@export var segments := 8
@export var segment_length := 0.13
@export var width := 0.11
@export var color := Color(0.95, 0.85, 0.3)
## Velocity kept per step (1 = no air drag).
@export var damping := 0.92
@export var gravity := 9.0
## Sideways flutter at speed (m).
@export var flutter := 0.04

var points := PackedVector3Array()
var _previous := PackedVector3Array()
var _mesh := ImmediateMesh.new()
var _clock := 0.0


func _ready() -> void:
	top_level = true
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	mesh = _mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.roughness = 0.9
	material_override = material


func set_color(new_color: Color) -> void:
	color = new_color
	if material_override:
		(material_override as StandardMaterial3D).albedo_color = color


func reset(anchor: Vector3) -> void:
	points.resize(segments + 1)
	_previous.resize(segments + 1)
	for i in segments + 1:
		points[i] = anchor + Vector3.DOWN * segment_length * i
		_previous[i] = points[i]


## One step: the first point follows the anchor, the rest swing behind.
func step(delta: float, anchor: Vector3, velocity: Vector3) -> void:
	if points.size() != segments + 1 or points[0].distance_to(anchor) > 5.0:
		reset(anchor)
	_clock += delta
	var dt := clampf(delta, 0.001, 1.0 / 30.0)
	var speed := velocity.length()
	var side := velocity.cross(Vector3.UP).normalized() if speed > 1.0 else Vector3.RIGHT
	for i in range(1, points.size()):
		var current := points[i]
		var moved := (current - _previous[i]) * damping
		var wave := side * sin(_clock * 18.0 + i * 0.9) * flutter * clampf(speed / 30.0, 0.0, 1.0) * i / segments
		_previous[i] = current
		points[i] = current + moved + Vector3.DOWN * gravity * dt * dt + wave
	points[0] = anchor
	_previous[0] = anchor
	for iteration in 4:
		for i in range(1, points.size()):
			var d := points[i] - points[i - 1]
			var length := d.length()
			if length > 0.0001:
				points[i] = points[i - 1] + d / length * segment_length
	_draw_ribbon()


func _draw_ribbon() -> void:
	global_transform = Transform3D.IDENTITY
	_mesh.clear_surfaces()
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for i in points.size():
		var along := (points[mini(i + 1, points.size() - 1)] - points[maxi(i - 1, 0)]).normalized()
		var across := along.cross(Vector3.UP)
		if across.length_squared() < 0.001:
			across = along.cross(Vector3.RIGHT)
		across = across.normalized() * width * 0.5 * (1.0 - 0.4 * i / segments)
		_mesh.surface_add_vertex(points[i] - across)
		_mesh.surface_add_vertex(points[i] + across)
	_mesh.surface_end()
