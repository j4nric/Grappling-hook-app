extends MeshInstance3D
## Draws world-space lines (rope, aim preview). Purely visual.
## With thickness > 0 every segment is a thin square tube, so the line stays
## visible in the low-resolution pixel view.

@export var color := Color(0.91, 0.77, 0.28)
## Tube width (m); 0 draws plain 1-pixel lines.
@export var thickness := 0.0

var _mesh := ImmediateMesh.new()


func _ready() -> void:
	top_level = true
	mesh = _mesh
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.albedo_color = color
	if color.a < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material_override = mat
	visible = false


func update_line(from: Vector3, to: Vector3) -> void:
	update_points(PackedVector3Array([from, to]))


## Polyline through points; dashed draws every other segment.
func update_points(points: PackedVector3Array, dashed := false) -> void:
	global_transform = Transform3D.IDENTITY
	_mesh.clear_surfaces()
	var verts := PackedVector3Array()
	var step := 2 if dashed else 1
	for i in range(0, points.size() - 1, step):
		if points[i].is_equal_approx(points[i + 1]):
			continue
		if thickness <= 0.0:
			verts.append(points[i])
			verts.append(points[i + 1])
		else:
			_add_tube(verts, points[i], points[i + 1])
	if verts.is_empty():
		return
	_mesh.surface_begin(Mesh.PRIMITIVE_LINES if thickness <= 0.0 else Mesh.PRIMITIVE_TRIANGLES)
	for v in verts:
		_mesh.surface_add_vertex(v)
	_mesh.surface_end()


func _add_tube(verts: PackedVector3Array, a: Vector3, b: Vector3) -> void:
	var dir := (b - a).normalized()
	var side := dir.cross(Vector3.UP)
	if side.length_squared() < 0.001:
		side = dir.cross(Vector3.RIGHT)
	side = side.normalized() * thickness * 0.5
	var up := side.cross(dir).normalized() * thickness * 0.5
	var corners := [side + up, -side + up, -side - up, side - up]
	for k in 4:
		var c0: Vector3 = corners[k]
		var c1: Vector3 = corners[(k + 1) % 4]
		verts.append_array([a + c0, b + c0, b + c1, a + c0, b + c1, a + c1])
