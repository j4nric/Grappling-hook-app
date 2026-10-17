extends MeshInstance3D
## Draws world-space lines (rope, aim preview). Purely visual.
## Replace later with a textured/segmented rope if wanted.

@export var color := Color(0.91, 0.77, 0.28)

var _mesh := ImmediateMesh.new()


func _ready() -> void:
	top_level = true
	mesh = _mesh
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	if color.a < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material_override = mat
	visible = false


func update_line(from: Vector3, to: Vector3) -> void:
	global_transform = Transform3D.IDENTITY
	_mesh.clear_surfaces()
	_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	_mesh.surface_add_vertex(from)
	_mesh.surface_add_vertex(to)
	_mesh.surface_end()


## Polyline through points; dashed draws every other segment.
func update_points(points: PackedVector3Array, dashed := false) -> void:
	global_transform = Transform3D.IDENTITY
	_mesh.clear_surfaces()
	if points.size() < 2:
		return
	_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	var step := 2 if dashed else 1
	for i in range(0, points.size() - 1, step):
		_mesh.surface_add_vertex(points[i])
		_mesh.surface_add_vertex(points[i + 1])
	_mesh.surface_end()
