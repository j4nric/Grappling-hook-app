extends MeshInstance3D
## Draws the rope as a single world-space line. Purely visual.
## Replace later with a textured/segmented rope if wanted.

var _mesh := ImmediateMesh.new()


func _ready() -> void:
	top_level = true
	mesh = _mesh
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.91, 0.77, 0.28)
	material_override = mat
	visible = false


func update_line(from: Vector3, to: Vector3) -> void:
	global_transform = Transform3D.IDENTITY
	_mesh.clear_surfaces()
	_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	_mesh.surface_add_vertex(from)
	_mesh.surface_add_vertex(to)
	_mesh.surface_end()
