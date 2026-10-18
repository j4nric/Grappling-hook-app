class_name PlayerFigure
extends Node3D
## The climber: simple meshes on joint pivots (hips, chest, head, shoulders,
## elbows, hips, knees), posed every rendered frame from the player's state.
## The rope arm reaches for the anchor or the flying hook, the free arm and
## the legs trail in the airflow, a zip launch throws a somersault, landings
## crouch. A scarf (verlet band) shows speed and direction. On a fatal fall
## the figure goes limp (go_limp()) and tumbles on by itself until snap().
## Purely visual: player.gd calls update_pose() from its _process.

const JACKET := Color(0.72, 0.22, 0.16)
const PANTS := Color(0.2, 0.22, 0.28)
const SKIN := Color(0.93, 0.74, 0.58)
const PACK := Color(0.3, 0.32, 0.22)
const BOOTS := Color(0.22, 0.15, 0.1)
const HELMET := Color(0.9, 0.7, 0.15)
const SCARF := Color(0.95, 0.85, 0.3)

## How fast the body turns into its pose (1/s).
@export var turn_speed := 10.0
## How fast the limbs follow their pose (1/s).
@export var limb_speed := 14.0
## Somersault length after a zip launch (s).
@export var flip_time := 0.45
## From this speed (m/s) the body lies into the flight (head first).
@export var dive_speed := 18.0
## Limp fall: gravity (m/s²) and how fast the body tumbles (rad/s).
@export var limp_gravity := 25.0
@export var limp_spin := 6.0

## Falling limp (go_limp()): moves by itself, update_pose() ignores the body.
var limp := false
var _limp_velocity := Vector3.ZERO
var _limp_axis := Vector3.RIGHT

var hips: Node3D
var chest: Node3D
var head: Node3D
var arm_r: Node3D
var elbow_r: Node3D
var hand_r: Node3D
var arm_l: Node3D
var elbow_l: Node3D
var hand_l: Node3D
var leg_r: Node3D
var knee_r: Node3D
var leg_l: Node3D
var knee_l: Node3D
var lamp: SpotLight3D

var scarf: VerletBand
## Somersault progress 0..1 (1 = none running).
var flip := 1.0
var _crouch := 0.0
var _clock := 0.0
var _forward := Vector3.FORWARD
var _body := Basis.IDENTITY


func _ready() -> void:
	top_level = true
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_build()
	scarf = VerletBand.new()
	scarf.name = "Scarf"
	add_child(scarf)


## Starts the somersault of a zip launch.
func start_flip() -> void:
	flip = 0.0


## Squat on landing; strength 0..1.
func land(strength: float) -> void:
	_crouch = maxf(_crouch, clampf(strength, 0.0, 1.0))


## Lava or a fall: the figure flies on with the speed it had (a little
## slower, with a small hop), tumbles and lets its limbs flop.
func go_limp(velocity: Vector3) -> void:
	limp = true
	flip = 1.0
	_limp_velocity = velocity * 0.6 + Vector3.UP * 4.0
	# Head over heels in the flight direction (the same fall looks the same).
	var side := Vector3(velocity.x, 0.0, velocity.z).cross(Vector3.UP)
	_limp_axis = (side.normalized() if side.length() > 0.5 else _body.x) + Vector3.UP * 0.3


## Teleport: no smoothing from the old place.
func snap(origin: Vector3) -> void:
	limp = false
	global_position = origin
	_body = Basis.IDENTITY
	scarf.reset(origin)


func hand_position() -> Vector3:
	return hand_r.global_position


## state: velocity (Vector3), on_floor (bool), target (Vector3 or null: the
## anchor or the flying hook the rope hand reaches for), aim (Vector3 or
## null: aiming direction).
func update_pose(delta: float, origin: Vector3, state: Dictionary) -> void:
	_clock += delta
	if limp:
		_fall_limp(delta)
		return
	global_position = origin
	var velocity: Vector3 = state.velocity
	var speed := velocity.length()
	var on_floor: bool = state.on_floor
	var target = state.get("target")
	var aim = state.get("aim")

	# Facing: along the horizontal movement, else keep the last direction.
	var flat := Vector3(velocity.x, 0.0, velocity.z)
	if aim != null:
		flat = Vector3(aim.x, 0.0, aim.z)
	if flat.length() > 1.5:
		_forward = _forward.slerp(flat.normalized(), 1.0 - exp(-6.0 * delta)).normalized()

	# Up: hanging from the rope, lying into a fast flight, else upright.
	var up := Vector3.UP
	if target != null and not on_floor:
		up = Vector3.UP.slerp(origin.direction_to(target), 0.6)
	elif not on_floor and speed > dive_speed:
		up = Vector3.UP.slerp(velocity / speed, clampf((speed - dive_speed) / 25.0, 0.0, 0.75))
	var goal := _basis_from(up.normalized(), _forward)
	_body = _body.slerp(goal, 1.0 - exp(-turn_speed * delta)).orthonormalized()

	# Somersault around the body's side axis after a zip.
	var flip_basis := Basis.IDENTITY
	if flip < 1.0:
		flip = minf(1.0, flip + delta / flip_time)
		var eased := 1.0 - pow(1.0 - flip, 2.0)
		flip_basis = Basis(Vector3.RIGHT, -TAU * eased)
	basis = _body * flip_basis

	_crouch = move_toward(_crouch, 0.0, delta * 2.5)
	var k := 1.0 - exp(-limb_speed * delta)
	var airborne := not on_floor
	var drift := clampf(speed / 30.0, 0.0, 1.0) if airborne else 0.0
	var breath := sin(_clock * 2.2) * 0.03

	# Rope arm: straight at the target, else ready by the side.
	if target != null:
		_point(arm_r, target, k)
		_bend(elbow_r, 0.05, k)
	elif aim != null:
		_point(arm_r, origin + aim * 5.0 + Vector3.UP * 2.0, k)
		_bend(elbow_r, 0.2, k)
	else:
		_rotate_to(arm_r, Vector3(0.2 + breath, 0.0, 0.25), k)
		_bend(elbow_r, 0.5, k)
	# Free arm: out to the side for balance, swept back at speed.
	if airborne:
		_rotate_to(arm_l, Vector3(0.6 + drift * 1.2, 0.0, -0.9 + drift * 0.5), k)
		_bend(elbow_l, 0.6 - drift * 0.4, k)
	else:
		_rotate_to(arm_l, Vector3(0.2 - breath, 0.0, -0.25), k)
		_bend(elbow_l, 0.5, k)

	# Legs: stand (or squat) on the floor, trail and kick in the air.
	if airborne:
		var kick := sin(_clock * 6.0) * 0.35 * (1.0 - drift)
		_rotate_to(leg_r, Vector3(0.35 + drift * 0.6 + kick, 0.0, 0.08), k)
		_rotate_to(leg_l, Vector3(0.15 + drift * 0.7 - kick, 0.0, -0.08), k)
		_bend(knee_r, 0.9 - drift * 0.5, k)
		_bend(knee_l, 0.5 - drift * 0.3, k)
	else:
		_rotate_to(leg_r, Vector3(-_crouch * 1.1, 0.0, 0.04), k)
		_rotate_to(leg_l, Vector3(-_crouch * 1.1, 0.0, -0.04), k)
		_bend(knee_r, _crouch * 2.0, k)
		_bend(knee_l, _crouch * 2.0, k)
	hips.position.y = lerpf(hips.position.y, -0.05 - _crouch * 0.3, k)
	chest.rotation.x = lerpf(chest.rotation.x, -_crouch * 0.4 + breath - drift * 0.15, k)
	head.rotation.x = lerpf(head.rotation.x, drift * 0.5, k)

	scarf.step(delta, chest.to_global(Vector3(0.0, 0.48, 0.12)), velocity)


## One frame of the limp fall: ballistic flight, tumbling body, limbs
## loose and slow (low stiffness), each swinging at its own beat.
func _fall_limp(delta: float) -> void:
	_limp_velocity.y -= limp_gravity * delta
	global_position += _limp_velocity * delta
	_body = (Basis(_limp_axis.normalized(), limp_spin * delta) * _body).orthonormalized()
	basis = _body
	var k := 1.0 - exp(-5.0 * delta)
	var t := _clock
	_rotate_to(arm_r, Vector3(2.4 + sin(t * 7.0) * 0.6, 0.0, 0.9 + sin(t * 5.3) * 0.4), k)
	_rotate_to(arm_l, Vector3(2.2 + sin(t * 6.1 + 1.0) * 0.6, 0.0, -1.0 + sin(t * 4.7) * 0.4), k)
	_bend(elbow_r, 0.8 + sin(t * 8.0) * 0.5, k)
	_bend(elbow_l, 0.7 + sin(t * 7.3 + 2.0) * 0.5, k)
	_rotate_to(leg_r, Vector3(0.9 + sin(t * 5.0) * 0.5, 0.0, 0.3), k)
	_rotate_to(leg_l, Vector3(-0.3 + sin(t * 5.7 + 1.5) * 0.5, 0.0, -0.3), k)
	_bend(knee_r, 1.2 + sin(t * 6.4) * 0.4, k)
	_bend(knee_l, 0.6 + sin(t * 6.9 + 0.5) * 0.4, k)
	chest.rotation.x = lerpf(chest.rotation.x, sin(t * 4.0) * 0.4, k)
	head.rotation.x = lerpf(head.rotation.x, 0.6 + sin(t * 5.0) * 0.4, k)
	scarf.step(delta, chest.to_global(Vector3(0.0, 0.48, 0.12)), _limp_velocity)


## Points a limb pivot (rest pose: hanging down, -Y) at a world position.
func _point(limb: Node3D, world_target: Vector3, k: float) -> void:
	var parent := limb.get_parent() as Node3D
	var local_dir := parent.global_basis.inverse() * (world_target - limb.global_position)
	if local_dir.length_squared() < 0.0001:
		return
	var goal := Quaternion(Vector3.DOWN, local_dir.normalized())
	limb.quaternion = limb.quaternion.slerp(goal, k)


func _rotate_to(limb: Node3D, euler: Vector3, k: float) -> void:
	limb.quaternion = limb.quaternion.slerp(Quaternion.from_euler(euler), k)


func _bend(joint: Node3D, angle: float, k: float) -> void:
	joint.rotation = Vector3(lerpf(joint.rotation.x, angle, k), 0.0, 0.0)


static func _basis_from(up: Vector3, forward: Vector3) -> Basis:
	var back := -forward
	back = (back - up * back.dot(up))
	if back.length_squared() < 0.0001:
		back = Vector3.BACK - up * Vector3.BACK.dot(up)
	back = back.normalized()
	var right := up.cross(back).normalized()
	return Basis(right, up, back)


# --- Model ---------------------------------------------------------------------

func _build() -> void:
	hips = _pivot(self, "Hips", Vector3(0, -0.05, 0))
	_part(hips, BoxMesh, Vector3(0.34, 0.18, 0.2), Vector3.ZERO, PANTS)
	chest = _pivot(hips, "Chest", Vector3(0, 0.05, 0))
	_part(chest, BoxMesh, Vector3(0.38, 0.45, 0.22), Vector3(0, 0.25, 0), JACKET)
	_part(chest, BoxMesh, Vector3(0.3, 0.38, 0.16), Vector3(0, 0.27, 0.18), PACK)
	head = _pivot(chest, "Head", Vector3(0, 0.5, 0))
	_part(head, SphereMesh, Vector3(0.3, 0.3, 0.3), Vector3(0, 0.16, 0), SKIN)
	_part(head, SphereMesh, Vector3(0.34, 0.2, 0.34), Vector3(0, 0.26, 0.01), HELMET)
	var lamp_mesh := _part(head, BoxMesh, Vector3(0.08, 0.06, 0.05), Vector3(0, 0.27, -0.17), Color(1, 0.95, 0.7))
	var lamp_material := lamp_mesh.material_override as StandardMaterial3D
	lamp_material.emission_enabled = true
	lamp_material.emission = Color(1, 0.9, 0.6)
	lamp_material.emission_energy_multiplier = 2.0
	# Head lamp: off by default; dark halls switch it on.
	lamp = SpotLight3D.new()
	lamp.name = "Lamp"
	lamp.position = Vector3(0, 0.27, -0.2)
	lamp.light_color = Color(1, 0.92, 0.75)
	lamp.light_energy = 3.0
	lamp.spot_range = 30.0
	lamp.spot_angle = 32.0
	lamp.visible = false
	head.add_child(lamp)
	var arms := _limb(chest, "R", Vector3(0.25, 0.42, 0), 0.3, 0.28, 0.06, JACKET, SKIN)
	arm_r = arms[0]
	elbow_r = arms[1]
	hand_r = arms[2]
	arms = _limb(chest, "L", Vector3(-0.25, 0.42, 0), 0.3, 0.28, 0.06, JACKET, SKIN)
	arm_l = arms[0]
	elbow_l = arms[1]
	hand_l = arms[2]
	var legs := _limb(hips, "LegR", Vector3(0.1, -0.08, 0), 0.38, 0.36, 0.075, PANTS, BOOTS)
	leg_r = legs[0]
	knee_r = legs[1]
	legs = _limb(hips, "LegL", Vector3(-0.1, -0.08, 0), 0.38, 0.36, 0.075, PANTS, BOOTS)
	leg_l = legs[0]
	knee_l = legs[1]


## Upper part, joint, lower part and end (hand or foot): [upper, joint, end].
func _limb(parent: Node3D, tag: String, at: Vector3, upper: float, lower: float,
		radius: float, color: Color, end_color: Color) -> Array:
	var top := _pivot(parent, "Upper" + tag, at)
	_part(top, CapsuleMesh, Vector3(radius, upper + radius * 2.0, 0), Vector3(0, -upper / 2.0, 0), color)
	var joint := _pivot(top, "Joint" + tag, Vector3(0, -upper, 0))
	_part(joint, CapsuleMesh, Vector3(radius * 0.85, lower + radius * 2.0, 0), Vector3(0, -lower / 2.0, 0), color)
	var end := _pivot(joint, "End" + tag, Vector3(0, -lower, 0))
	_part(end, SphereMesh, Vector3(radius * 2.2, radius * 2.2, radius * 2.6), Vector3.ZERO, end_color)
	return [top, joint, end]


func _pivot(parent: Node3D, pivot_name: String, at: Vector3) -> Node3D:
	var node := Node3D.new()
	node.name = pivot_name
	node.position = at
	parent.add_child(node)
	return node


## size: box size, sphere (x = width, y = height), capsule (x = radius, y = height).
func _part(parent: Node3D, kind: Variant, size: Vector3, at: Vector3, color: Color) -> MeshInstance3D:
	var mesh: Mesh
	if kind == BoxMesh:
		var box := BoxMesh.new()
		box.size = size
		mesh = box
	elif kind == SphereMesh:
		var sphere := SphereMesh.new()
		sphere.radius = size.x / 2.0
		sphere.height = size.y
		sphere.radial_segments = 8
		sphere.rings = 4
		mesh = sphere
	else:
		var capsule := CapsuleMesh.new()
		capsule.radius = size.x
		capsule.height = size.y
		capsule.radial_segments = 6
		capsule.rings = 1
		mesh = capsule
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.8
	instance.material_override = material
	instance.position = at
	parent.add_child(instance)
	return instance
