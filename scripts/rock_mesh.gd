class_name RockMesh
## Procedural rock models for the cave builder: lumpy boulders, tapering
## stalactites, knobbly pillars and thin hanging roots. Each kind comes in a
## few variants, built once and cached (they are shared by MultiMeshes).
## Flat-shaded and unit-sized (fits a 1 m box, like the BoxMesh it replaces),
## so a transform scales it to any size. Fixed seeds: the same every run.

const VARIANTS := 4
const KINDS := ["boulder", "stalactite", "pillar", "root"]

static var _cache := {}


## Mesh `variant` (any int, wrapped) of a kind.
static func get_mesh(kind: String, variant: int) -> ArrayMesh:
	var key := "%s_%d" % [kind, posmod(variant, VARIANTS)]
	if not _cache.has(key):
		_cache[key] = _build(kind, posmod(variant, VARIANTS))
	return _cache[key]


## A variant number from a position: the same spot always gets the same
## model, without touching the builder's random numbers.
static func variant_at(pos: Vector3) -> int:
	return absi(hash(pos.snapped(Vector3.ONE * 0.5)))


static func _build(kind: String, variant: int) -> ArrayMesh:
	var noise := FastNoiseLite.new()
	noise.seed = 1000 + variant * 37 + KINDS.find(kind) * 1009
	noise.frequency = 1.6
	match kind:
		"boulder":
			return _boulder(noise)
		"stalactite":
			return _lathe(noise, 7, 5, func(t: float) -> float: return 0.5 * (1.0 - t) * (1.0 - 0.25 * t) + 0.03,
					func(t: float) -> float: return -t, 0.22)
		"pillar":
			return _lathe(noise, 8, 6, func(t: float) -> float: return 0.42 + 0.08 * sin(t * PI * 2.0 + variant),
					func(t: float) -> float: return 0.5 - t, 0.25)
		_:
			return _lathe(noise, 4, 6, func(t: float) -> float: return 0.5 * (1.0 - t * 0.85),
					func(t: float) -> float: return -t, 0.6)


## Icosphere (two subdivisions), pushed in and out by noise: a boulder that
## fits the unit box.
static func _boulder(noise: FastNoiseLite) -> ArrayMesh:
	var t := (1.0 + sqrt(5.0)) / 2.0
	var verts: Array[Vector3] = []
	for v in [Vector3(-1, t, 0), Vector3(1, t, 0), Vector3(-1, -t, 0), Vector3(1, -t, 0),
			Vector3(0, -1, t), Vector3(0, 1, t), Vector3(0, -1, -t), Vector3(0, 1, -t),
			Vector3(t, 0, -1), Vector3(t, 0, 1), Vector3(-t, 0, -1), Vector3(-t, 0, 1)]:
		verts.append(v.normalized())
	var faces: Array[Vector3i] = [
		Vector3i(0, 11, 5), Vector3i(0, 5, 1), Vector3i(0, 1, 7), Vector3i(0, 7, 10), Vector3i(0, 10, 11),
		Vector3i(1, 5, 9), Vector3i(5, 11, 4), Vector3i(11, 10, 2), Vector3i(10, 7, 6), Vector3i(7, 1, 8),
		Vector3i(3, 9, 4), Vector3i(3, 4, 2), Vector3i(3, 2, 6), Vector3i(3, 6, 8), Vector3i(3, 8, 9),
		Vector3i(4, 9, 5), Vector3i(2, 4, 11), Vector3i(6, 2, 10), Vector3i(8, 6, 7), Vector3i(9, 8, 1)]
	for level in 2:
		var mids := {}
		var next: Array[Vector3i] = []
		for f in faces:
			var a := _midpoint(verts, mids, f.x, f.y)
			var b := _midpoint(verts, mids, f.y, f.z)
			var c := _midpoint(verts, mids, f.z, f.x)
			next.append_array([Vector3i(f.x, a, c), Vector3i(f.y, b, a), Vector3i(f.z, c, b), Vector3i(a, b, c)])
		faces = next
	var lowest := INF
	var highest := -INF
	for i in verts.size():
		var d := verts[i]
		var r := 1.0 + 0.32 * noise.get_noise_3dv(d) + 0.12 * noise.get_noise_3dv(d * 3.1)
		# Flatter top and bottom: stones rest and hang believably.
		verts[i] = Vector3(d.x * r, d.y * r * 0.78, d.z * r)
		lowest = minf(lowest, verts[i].y)
		highest = maxf(highest, verts[i].y)
	var extent := 0.0
	for v in verts:
		extent = maxf(extent, maxf(absf(v.x), absf(v.z)))
	var scale := Vector3(0.5 / extent, 1.0 / (highest - lowest), 0.5 / extent)
	var shift := -(highest + lowest) / 2.0
	var triangles := PackedVector3Array()
	for f in faces:
		for index in [f.x, f.y, f.z]:
			var v: Vector3 = verts[index]
			triangles.append(Vector3(v.x, v.y + shift, v.z) * scale)
	return _commit(triangles, func(center: Vector3) -> Vector3: return center)


static func _midpoint(verts: Array[Vector3], mids: Dictionary, a: int, b: int) -> int:
	var key := Vector2i(mini(a, b), maxi(a, b))
	if not mids.has(key):
		verts.append(((verts[a] + verts[b]) / 2.0).normalized())
		mids[key] = verts.size() - 1
	return mids[key]


## A shape turned around the Y axis: `rings` + 1 rings from t = 0 to 1, the
## radius and height of each from the callables, roughened by noise.
static func _lathe(noise: FastNoiseLite, sides: int, rings: int, radius: Callable, height: Callable, rough: float) -> ArrayMesh:
	var grid: Array = []
	for j in rings + 1:
		var t := float(j) / rings
		var row: Array[Vector3] = []
		for i in sides:
			var a := TAU * i / sides
			var dir := Vector3(cos(a), 0, sin(a))
			var r: float = radius.call(t) * (1.0 + rough * noise.get_noise_3d(dir.x * 1.3, t * 3.0, dir.z * 1.3))
			# The very tip closes to a point.
			if j == rings and radius.call(1.0) < 0.05:
				r = 0.0
			row.append(dir * r + Vector3.UP * float(height.call(t)))
		grid.append(row)
	var triangles := PackedVector3Array()
	for j in rings:
		var top: Array[Vector3] = grid[j]
		var bottom: Array[Vector3] = grid[j + 1]
		for i in sides:
			var k := (i + 1) % sides
			for v in [top[i], top[k], bottom[i], top[k], bottom[k], bottom[i]]:
				triangles.append(v)
	# Cap the top (and the bottom of a pillar).
	var first: Array[Vector3] = grid[0]
	var top_y := float(height.call(0.0))
	var bottom_y := float(height.call(1.0))
	for i in sides:
		triangles.append_array([Vector3.UP * top_y, first[i], first[(i + 1) % sides]])
	var last: Array[Vector3] = grid[rings]
	for i in sides:
		triangles.append_array([Vector3.UP * bottom_y, last[(i + 1) % sides], last[i]])
	var mid_y := (top_y + bottom_y) / 2.0
	# Outward: away from the axis on the sides, up or down at the caps.
	return _commit(triangles, func(center: Vector3) -> Vector3:
		var radial := Vector3(center.x, 0, center.z)
		return radial if radial.length() > 0.02 else Vector3(0, center.y - mid_y, 0))


## Flat-shaded mesh from a triangle list: each face gets its own normal,
## turned to point outward (`outward` gives the outside direction at a face
## center), with the winding to match (Godot's front faces are clockwise).
## UVs and tangents too, for the normal-mapped materials.
static func _commit(triangles: PackedVector3Array, outward: Callable) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for t in range(0, triangles.size(), 3):
		var a := triangles[t]
		var b := triangles[t + 1]
		var c := triangles[t + 2]
		var normal := (c - a).cross(b - a).normalized()
		var center := (a + b + c) / 3.0
		if normal.dot(outward.call(center)) < 0.0:
			normal = -normal
			var swap := b
			b = c
			c = swap
		for v in [a, b, c]:
			st.set_normal(normal)
			st.set_uv(Vector2(v.x + v.z, v.y))
			st.add_vertex(v)
	st.generate_tangents()
	return st.commit()
