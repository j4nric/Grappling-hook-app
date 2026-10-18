extends CharacterBody3D
## The player has no walking. It only has gravity, a thrown hook and momentum.
## Throw: the swipe direction aims, the flick speed sets how hard the hook is
## thrown (Pokémon GO style). The hook flies on an arc; where it hits, it
## sticks and the rope yanks the player toward it (after a short swing).
## Shortly before the anchor the rope lets go on its own and the player flies
## on with full speed ("zip launch").
##
## Chaining: a new throw while the rope pulls keeps the rope until the new
## hook bites (hand-over), so throwing early never costs momentum. A swipe
## while a hook is still in the air is buffered and thrown when that hook
## lands or misses.

signal hook_thrown
signal hook_attached(point: Vector3, normal: Vector3)
## The hook found nothing to stick to.
signal hook_missed
## reason: "zip", "contact", "blocked", "tap", "chain" (a new hook took
## over), "broke" (a brittle anchor broke off), "reset"
signal rope_released(reason: String)
signal landed(impact_speed: float)
## Hit a wall or the ceiling with speed and was redirected along it.
signal deflected(impact_speed: float)
## Squeezed between the floor and a moving obstacle.
signal crushed

## IDLE: nothing out. FLYING: only a thrown hook in the air. ATTACHED: a rope
## pulls (a second hook may be in the air, see is_hook_flying()).
enum HookState { IDLE, FLYING, ATTACHED }

## The hook does not stick to surfaces facing up more than this (floors).
const FLOOR_NORMAL_Y := 0.7
## Surfaces in this group never hold the hook (e.g. ice).
const NO_HOOK_GROUP := "no_hook"
## The hook and rope start here, relative to the body (the hand).
const HOOK_OFFSET := Vector3(0.0, 0.6, 0.0)
## cos(60°): wall hits steeper than this are crashes, not wall-kicks.
const WALL_KICK_MIN_GLANCE := 0.5

# --- Tuning (exposed in the inspector, change freely while playing) -----------
@export_group("Physics")
@export var gravity := 22.0
@export var max_speed := 50.0
## Braking on the floor (m/s²) when no rope pulls; stops endless sliding ...
@export var floor_friction := 25.0
## ... but above slide_speed (m/s) the player slides with this lighter
## braking, so landings keep their momentum.
@export var slide_friction := 6.0
@export var slide_speed := 8.0
## Share of the fall speed turned into forward speed on landing (a roll).
@export var landing_roll := 0.3

@export_group("Impacts")
## Hitting a wall or the ceiling faster than this (m/s) redirects the speed
## along the surface instead of losing it.
@export var deflect_min_speed := 8.0
## Share of the speed into the surface that is turned along it. Scaled by
## how glancing the hit is: a grazing hit keeps almost everything, a head-on
## hit almost nothing (it never turns a tiny sideways part into full speed,
## and never ends up faster than before the hit).
@export var deflect_keep := 1.0
## Walls: share of the speed into the wall bounced back (wall-kick) ...
@export var wall_bounce := 0.2
## ... plus this upward kick (m/s).
@export var wall_kick_up := 4.0

@export_group("Throw")
## Hook speed (m/s) per finger speed (px/s, 720 px wide screen).
@export var throw_speed_per_px := 0.015
@export var hook_min_speed := 8.0
@export var hook_max_speed := 90.0
## Gravity on the flying hook. Higher = weak throws drop sooner.
@export var hook_gravity := 25.0
## Angle above the horizon for a straight-up swipe (degrees).
@export var throw_pitch := 50.0
## How strongly sideways swipes turn the throw toward the walls.
@export var throw_yaw_gain := 1.0
## A second swipe sooner than this (s) after a throw, while that hook still
## flies, is an accidental double swipe and is dropped.
@export var throw_cooldown := 0.12
## A swipe while a hook flies is kept this long (s) and thrown when the hook
## in the air bites or misses.
@export var throw_buffer_time := 0.3

@export_group("Aim")
## The aim preview shows the arc of a throw at this hook speed (m/s), about a
## good flick. The real throw depends on the flick.
@export var aim_preview_speed := 50.0
## Pitch assist: a throw that would not hold - ice, nothing in reach, or rock
## closer than this (m), as right under the ceiling - is thrown flatter, down
## to min_throw_pitch (degrees; = throw_pitch turns it off).
@export var min_throw_reach := 14.0
@export var min_throw_pitch := 5.0
## Aim assist: if the throw would find nothing to stick to, search this cone
## (degrees) for the closest wall or ceiling. 0 = off.
@export var aim_assist_angle := 0.0
## Game speed while the finger aims (1 = off, 0.5 = half speed).
@export var aim_time_scale := 1.0
## Seconds the hook takes to fly back after a miss or letting go.
@export var hook_retract_time := 0.2

@export_group("Rope")
## The hook gives up when it gets further away than this.
@export var max_rope_length := 70.0
## Hooks closer than this do not hold: there is nothing left to pull.
@export var min_hook_distance := 3.0
## Speed (m/s) toward the anchor added the moment the hook sticks: the yank.
@export var pull_impulse := 6.0
## After the hook sticks, the rope keeps its length this long (s): the player
## swings on it before the reel pulls. 0 = pull at once.
@export var swing_time := 0.0
## The rope shortens this fast right after the hook sticks (m/s) ...
@export var reel_speed := 8.0
## ... and this much faster every second (m/s²) ...
@export var reel_acceleration := 30.0
## ... up to this speed (m/s).
@export var reel_max_speed := 30.0
@export var min_rope_length := 0.5
## Extra acceleration toward the anchor; makes the pull feel heavier.
@export var tension_boost := 6.0
## The rope lets go this far before the anchor and the player flies on with
## full speed (zip launch). 0 = pull all the way.
@export var zip_release_distance := 2.5
## Extra speed (m/s) in flight direction at the zip launch.
@export var zip_boost := 3.0
## Flyby: passing the anchor (moving away from it faster than
## flyby_speed m/s) within this distance also lets go, instead of the rope
## swinging the player back.
@export var flyby_release_distance := 6.0
@export var flyby_speed := 2.0
## Touching a wall or the ceiling while attached lets go of the rope.
@export var release_on_contact := true
## No contact release right after the hook sticks (s), so a throw from close
## to a wall still pulls.
@export var contact_release_grace := 0.15
## A tap right after the hook sticks (s) does not let go: it is almost always
## an accidental touch at the end of the throw.
@export var tap_release_lock := 0.15
## Let go when level geometry gets between player and anchor.
@export var release_when_blocked := true

@export_group("Look")
## The rope twangs when the hook bites: wave height (m), 0 = off ...
@export var rope_pluck := 0.5
## ... and how fast it dies down (1/s).
@export var rope_pluck_decay := 9.0
## Rope length per straight distance while the hook flies (> 1: it sags).
@export var flight_rope_slack := 1.03

# --- State ---------------------------------------------------------------------
var hook_state := HookState.IDLE
## Anchor point of the attached rope.
var anchor := Vector3.ZERO
var rope_length := 0.0
## Position of the hook in the air.
var flight_position := Vector3.ZERO
var _attached := false
var _flying := false
var _hook_velocity := Vector3.ZERO
var _attached_time := 0.0
## Reel speed the current rope starts with (m/s): at least the speed the
## player already moves toward the anchor, so a new rope never brakes.
var _reel_base := 0.0
var _was_on_floor := false
## Flying hook position one physics tick ago, for smooth drawing.
var _flight_prev := Vector3.ZERO
## Moving body the hook sticks to, and the anchor in its local space.
var _anchor_body: Node3D = null
var _anchor_local := Vector3.ZERO
var _since_throw := INF
## Buffered throw: [swipe, flick] and how long it stays valid.
var _buffered: Array = []
var _buffer_left := 0.0
var _rope_visual: RopeVisual
var _flight_visual: RopeVisual
## Last throw, shown in the tuning panel to calibrate the throw strength.
var last_throw_flick := 0.0
var last_throw_speed := 0.0
## Replay of a recorded run: no physics and no input, Replay places the
## player (replay_step()); figure, rope and camera follow as usual.
var replaying := false:
	set(value):
		replaying = value
		reset_to(global_position)

@onready var rope := $Rope
@onready var hook: Node3D = $Hook
@onready var flight_rope := $FlightRope
@onready var flight_hook: Node3D = $FlightHook
@onready var aim_line := $AimLine
@onready var aim_marker: Node3D = $AimMarker
@onready var figure: PlayerFigure = $Figure

## Direction of the current aim (for the figure's pose), null when not aiming.
var _aim_direction = null


func _ready() -> void:
	InputRouter.aim_changed.connect(_on_aim_changed)
	InputRouter.aim_cancelled.connect(_on_aim_cancelled)
	InputRouter.throw_requested.connect(throw_hook)
	InputRouter.release_requested.connect(release)
	_rope_visual = RopeVisual.new(rope, hook)
	_flight_visual = RopeVisual.new(flight_rope, flight_hook)
	rope_released.connect(func(reason: String) -> void:
		if reason == "zip":
			figure.start_flip())
	landed.connect(func(speed: float) -> void: figure.land((speed - 4.0) / 20.0))
	aim_marker.top_level = true
	aim_marker.visible = false
	# Placed by hand every rendered frame.
	for node: Node3D in [aim_line, aim_marker]:
		node.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF


func _physics_process(delta: float) -> void:
	if replaying:
		return
	velocity.y -= gravity * delta
	_since_throw += delta
	_buffer_left -= delta

	if _flying:
		_fly_hook(delta)
	if _attached:
		_attached_time += delta
		if is_instance_valid(_anchor_body):
			anchor = _anchor_body.global_transform * _anchor_local
		if _is_flying_by():
			_zip_launch()
		else:
			_apply_rope_constraint(delta)

	if not _attached and is_on_floor():
		_apply_floor_friction(delta)

	velocity = velocity.limit_length(max_speed)
	var fall_speed := -velocity.y
	var before_slide := velocity
	move_and_slide()
	_handle_impacts(before_slide)

	if is_on_floor() and not _was_on_floor:
		_roll_on_landing(fall_speed)
		landed.emit(fall_speed)
	_was_on_floor = is_on_floor()

	# No grace for the zip: min_hook_distance already keeps a fresh hook out
	# of zip range, and a fast hand-over can reach the anchor within the grace.
	if _attached and zip_release_distance > 0.0 \
			and global_position.distance_to(anchor) <= zip_release_distance \
			and velocity.dot(global_position.direction_to(anchor)) > 0.0:
		_zip_launch()
	elif _attached and _attached_time >= contact_release_grace:
		if release_on_contact and _touches_wall_or_ceiling():
			release("contact")
		elif release_when_blocked and _is_rope_blocked():
			release("blocked")



## Visuals run per rendered frame (not per physics tick) with the
## interpolated body position, so rope and hook stay smooth at 120 Hz and
## when the frame rate drops.
func _process(delta: float) -> void:
	var body := get_global_transform_interpolated().origin
	var flight := _flight_prev.lerp(flight_position, Engine.get_physics_interpolation_fraction())
	var target = null
	if _attached:
		target = anchor
	elif _flying:
		target = flight
	figure.update_pose(delta, body, {"velocity": velocity, "on_floor": is_on_floor(),
			"target": target, "aim": _aim_direction})
	# The rope starts in the rope hand.
	var origin := figure.hand_position()
	if _flying:
		_flight_visual.show_at(origin, flight, delta, flight_rope_slack)
	else:
		_flight_visual.update_retract(delta, origin)
	if _attached:
		_rope_visual.show_at(origin, anchor, delta)
	else:
		_rope_visual.update_retract(delta, origin)


func is_hook_flying() -> bool:
	return _flying


func _update_state() -> void:
	if _attached:
		hook_state = HookState.ATTACHED
	elif _flying:
		hook_state = HookState.FLYING
	else:
		hook_state = HookState.IDLE


## Rope pull, applied as velocity so the momentum survives letting go.
## The player may move freely inside the rope sphere; leaving it is corrected
## by adding exactly the inward speed needed, which turns falling into swinging.
## The reel starts at reel_speed and accelerates, so the pull builds up.
func _apply_rope_constraint(delta: float) -> void:
	var reel_time := _attached_time - swing_time
	if reel_time > 0.0:
		var reel := minf(_reel_base + reel_acceleration * reel_time, reel_max_speed)
		rope_length = maxf(min_rope_length, rope_length - reel * delta)

	var to_anchor := anchor - global_position
	var distance := to_anchor.length()
	if distance < 0.001:
		return
	var dir_to_anchor := to_anchor / distance

	velocity += dir_to_anchor * tension_boost * delta

	var inward_speed := velocity.dot(dir_to_anchor)
	var needed := (distance - rope_length) / delta
	if inward_speed < needed:
		velocity += dir_to_anchor * (needed - inward_speed)
	# Arrive at the anchor without overshooting it.
	var max_inward := maxf(0.0, distance - min_rope_length) / delta
	inward_speed = velocity.dot(dir_to_anchor)
	if inward_speed > max_inward:
		velocity -= dir_to_anchor * (inward_speed - max_inward)


## True when the player has passed the anchor while the reel pulls: the
## velocity (before the rope corrects it) points away from a nearby anchor.
func _is_flying_by() -> bool:
	if _attached_time < swing_time:
		return false
	var to_anchor := anchor - global_position
	var distance := to_anchor.length()
	if distance > flyby_release_distance or distance < 0.001:
		return false
	return velocity.dot(to_anchor / distance) < -flyby_speed


func _apply_floor_friction(delta: float) -> void:
	var flat := Vector2(velocity.x, velocity.z)
	var friction := slide_friction if flat.length() > slide_speed else floor_friction
	flat = flat.move_toward(Vector2.ZERO, friction * delta)
	velocity.x = flat.x
	velocity.z = flat.y


## Walls and the ceiling redirect speed instead of eating it; walls also
## kick back. A moving obstacle pressing down onto a grounded player crushes.
func _handle_impacts(before: Vector3) -> void:
	if _is_crushed():
		crushed.emit()
		return
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var normal := collision.get_normal()
		if normal.y > FLOOR_NORMAL_Y:
			continue
		# A taut rope that drags the player into a surface is not momentum
		# worth keeping (the contact release lets go of it anyway).
		if _attached:
			continue
		var into := -before.dot(normal)
		var speed := before.length()
		if into <= 0.0 or speed < deflect_min_speed:
			continue
		var along := before - normal * before.dot(normal)
		var glance := along.length() / speed
		var redirected := velocity
		if along.length() > 0.5:
			var kept := minf(along.length() + into * deflect_keep * glance, speed)
			redirected = along.normalized() * kept
		# Only a glancing hit (under ~60° to the wall) kicks off; a head-on
		# crash into an obstacle slides along it instead of bouncing back.
		if absf(normal.y) < 0.5 and glance > WALL_KICK_MIN_GLANCE:
			redirected += normal * into * wall_bounce + Vector3.UP * wall_kick_up
		velocity = redirected.limit_length(max_speed)
		deflected.emit(into)
		return


## Floor below and a moving obstacle pressing from above. (A pusher shows up
## only in is_on_ceiling(), not in the slide collisions, so look up once.)
func _is_crushed() -> bool:
	if not (is_on_floor() and is_on_ceiling()):
		return false
	var hit := KinematicCollision3D.new()
	return test_move(global_transform, Vector3.UP * 0.1, hit) and hit.get_collider() is AnimatableBody3D


func _roll_on_landing(fall_speed: float) -> void:
	var flat := Vector3(velocity.x, 0.0, velocity.z)
	if fall_speed > 0.0 and flat.length() > 1.0:
		velocity += flat.normalized() * fall_speed * landing_roll
		velocity = velocity.limit_length(max_speed)


func _zip_launch() -> void:
	var speed := velocity.length()
	if speed > 0.001:
		velocity = (velocity + velocity / speed * zip_boost).limit_length(max_speed)
	release("zip")


## True when level geometry lies between the player and the anchor.
func _is_rope_blocked() -> bool:
	var from := _hook_origin()
	var query := PhysicsRayQueryParameters3D.create(from, anchor)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	# The anchor surface itself is not an obstacle.
	return not hit.is_empty() and hit.position.distance_to(anchor) > 0.3


## True if the hook holds on the surface of this ray hit: walls, ceilings,
## obstacles; not floors and not surfaces in the no_hook group.
static func can_stick(hit: Dictionary) -> bool:
	if hit.is_empty() or hit.normal.y > FLOOR_NORMAL_Y:
		return false
	var collider: Object = hit.collider
	return not (collider is Node and (collider as Node).is_in_group(NO_HOOK_GROUP))


## Sticks the hook at point and starts the pull. On a moving body the anchor
## moves along. An already attached rope hands over to the new one.
func attach(point: Vector3, normal: Vector3, body: Object = null) -> void:
	if _attached:
		_rope_visual.retract(anchor, hook_retract_time * 0.5)
		rope_released.emit("chain")
	_anchor_body = body as AnimatableBody3D
	if _anchor_body:
		_anchor_local = _anchor_body.global_transform.affine_inverse() * point
	# A brittle stalactite holds for a moment, then breaks: the rope goes.
	if body is Brittle:
		var brittle := body as Brittle
		brittle.hooked()
		if not brittle.broken.is_connected(_on_anchor_broken):
			brittle.broken.connect(_on_anchor_broken.bind(brittle))
	anchor = point
	rope_length = global_position.distance_to(anchor)
	var approach := velocity.dot(global_position.direction_to(anchor))
	_reel_base = clampf(approach, reel_speed, reel_max_speed)
	_attached = true
	_attached_time = 0.0
	_update_state()
	velocity += global_position.direction_to(anchor) * pull_impulse
	_rope_visual.pluck(rope_pluck, rope_pluck_decay)
	hook_attached.emit(point, normal)


func _on_anchor_broken(body: Brittle) -> void:
	if _attached and _anchor_body == body:
		release("broke")


func _fly_hook(delta: float) -> void:
	_flight_prev = flight_position
	_hook_velocity.y -= hook_gravity * delta
	var next := flight_position + _hook_velocity * delta
	var query := PhysicsRayQueryParameters3D.create(flight_position, next)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		flight_position = hit.position
		if not can_stick(hit) or global_position.distance_to(hit.position) < min_hook_distance:
			_miss()
			return
		_flying = false
		_flight_visual.hide()
		attach(hit.position, hit.normal, hit.collider)
		_throw_buffered()
	elif next.distance_to(global_position) > max_rope_length:
		_miss()
	else:
		flight_position = next


func _touches_wall_or_ceiling() -> bool:
	for i in get_slide_collision_count():
		if get_slide_collision(i).get_normal().y <= FLOOR_NORMAL_Y:
			return true
	return false


## Screen swipe -> 3D throw direction. Straight up on screen throws forward
## (-Z) and up at throw_pitch; sideways swipes turn the throw toward the walls.
## Aim assist may bend it toward the closest surface the hook can stick to.
## Throw direction for a swipe and a hook speed: yaw from the swipe, pitch
## throw_pitch - unless that throw would not hold (ice, nothing in reach, or
## rock closer than min_throw_reach, as right under the ceiling): then the
## first flatter pitch that holds, down to min_throw_pitch.
func _throw_direction(swipe: Vector2, speed: float) -> Vector3:
	var s := Vector2(swipe.x, -swipe.y).normalized()
	var yaw := atan2(s.x, s.y) * throw_yaw_gain
	var dir := _pitched(yaw, throw_pitch)
	if is_inside_tree() and not _holds(dir, speed):
		var pitch := throw_pitch
		while pitch > min_throw_pitch:
			pitch = maxf(pitch - 10.0, min_throw_pitch)
			var flatter := _pitched(yaw, pitch)
			if _holds(flatter, speed):
				dir = flatter
				break
	return _assisted_direction(dir)


func _pitched(yaw: float, pitch_degrees: float) -> Vector3:
	var pitch := deg_to_rad(pitch_degrees)
	return Vector3(sin(yaw) * cos(pitch), sin(pitch), -cos(yaw) * cos(pitch))


func _holds(dir: Vector3, speed: float) -> bool:
	var path := predict_hook_path(dir, speed)
	var points: PackedVector3Array = path.points
	return path.hit and global_position.distance_to(points[-1]) >= min_throw_reach


func _assisted_direction(dir: Vector3) -> Vector3:
	if aim_assist_angle <= 0.0 or _sticks_along(dir):
		return dir
	var side := dir.cross(Vector3.UP).normalized()
	if side.is_zero_approx():
		side = Vector3.RIGHT
	for ring in range(1, 4):
		var angle := deg_to_rad(aim_assist_angle) * ring / 3.0
		for k in 12:
			var axis := side.rotated(dir, TAU * k / 12.0)
			var candidate := dir.rotated(axis, angle)
			if _sticks_along(candidate):
				return candidate
	return dir


## True if a straight ray along dir hits a wall or ceiling within rope range.
func _sticks_along(dir: Vector3) -> bool:
	var from := _hook_origin()
	var query := PhysicsRayQueryParameters3D.create(from, from + dir * max_rope_length)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return can_stick(hit)


## Simulates the hook flight like _fly_hook(). Returns the arc points; the last
## point is where it sticks (hit = true) or gives up.
func predict_hook_path(dir: Vector3, speed: float) -> Dictionary:
	var points := PackedVector3Array()
	var pos := _hook_origin()
	var vel := dir * speed + velocity
	var space := get_world_3d().direct_space_state
	points.append(pos)
	for i in 180:
		vel.y -= hook_gravity / 60.0
		var next := pos + vel / 60.0
		var query := PhysicsRayQueryParameters3D.create(pos, next)
		query.exclude = [get_rid()]
		var hit := space.intersect_ray(query)
		if not hit.is_empty():
			points.append(hit.position)
			var holds := can_stick(hit) and global_position.distance_to(hit.position) >= min_hook_distance
			return {"points": points, "hit": holds}
		if next.distance_to(global_position) > max_rope_length:
			break
		pos = next
		points.append(pos)
	return {"points": points, "hit": false}


## Downward swipes would throw backwards; they cancel instead.
func _is_valid_swipe(swipe: Vector2) -> bool:
	return -swipe.y > -0.25 * swipe.length()


func _hook_origin() -> Vector3:
	return global_position + HOOK_OFFSET


func _on_aim_changed(swipe: Vector2) -> void:
	if replaying:
		return
	TimeScale.set_aim(aim_time_scale)
	if not _is_valid_swipe(swipe):
		_hide_aim()
		return
	var direction := _throw_direction(swipe, aim_preview_speed)
	_aim_direction = direction
	var path := predict_hook_path(direction, aim_preview_speed)
	var points: PackedVector3Array = path.points
	aim_line.update_points(points, true)
	aim_line.visible = true
	aim_marker.visible = path.hit
	aim_marker.global_position = points[-1]


func _on_aim_cancelled() -> void:
	_hide_aim()
	TimeScale.set_aim(1.0)


func _hide_aim() -> void:
	_aim_direction = null
	aim_line.visible = false
	aim_marker.visible = false


## Throws the hook. The attached rope keeps pulling until the new hook bites.
## While a hook flies, the swipe is buffered instead.
func throw_hook(swipe: Vector2, flick_velocity: Vector2) -> void:
	if replaying:
		return
	_hide_aim()
	TimeScale.set_aim(1.0)
	if not _is_valid_swipe(swipe):
		return
	if _flying:
		# A second swipe right after a throw is an accidental double swipe;
		# a later one is kept for when this hook bites or misses.
		if _since_throw >= throw_cooldown:
			_buffered = [swipe, flick_velocity]
			_buffer_left = throw_buffer_time
		return
	var speed := clampf(flick_velocity.length() * throw_speed_per_px, hook_min_speed, hook_max_speed)
	last_throw_flick = flick_velocity.length()
	last_throw_speed = speed
	_since_throw = 0.0
	flight_position = _hook_origin()
	_flight_prev = flight_position
	_hook_velocity = _throw_direction(swipe, speed) * speed + velocity
	_flying = true
	_update_state()
	hook_thrown.emit()


func _throw_buffered() -> void:
	if _buffered.is_empty():
		return
	var throw: Array = _buffered
	_buffered = []
	if _buffer_left > 0.0:
		_since_throw = INF
		throw_hook(throw[0], throw[1])


func _miss() -> void:
	_flying = false
	_flight_visual.retract(flight_position, hook_retract_time)
	_update_state()
	hook_missed.emit()
	_throw_buffered()


## Lets go of the attached rope (a tap without a rope calls back a hook in
## the air). Signals only if something was out.
func release(reason := "tap") -> void:
	if replaying:
		return
	if not _attached:
		if _flying and reason == "tap":
			_flying = false
			_flight_visual.retract(flight_position, hook_retract_time)
			_update_state()
			rope_released.emit(reason)
		return
	if reason == "tap" and _attached_time < tap_release_lock:
		return
	_attached = false
	_anchor_body = null
	_rope_visual.retract(anchor, hook_retract_time)
	_update_state()
	rope_released.emit(reason)


## One step of a replay (call in _physics_process): the player is at pos
## with this velocity, on a rope to rope_anchor (Ghost.NO_ANCHOR: none).
## jump: a teleport (respawn in the recording), not interpolated.
func replay_step(pos: Vector3, vel: Vector3, rope_anchor: Vector3, jump := false) -> void:
	global_position = pos
	velocity = vel
	var hooked := rope_anchor.is_finite()
	if hooked and not _attached:
		_rope_visual.pluck(0.3, 9.0)
	elif not hooked and _attached:
		_rope_visual.retract(anchor, hook_retract_time)
	if hooked:
		anchor = rope_anchor
	_attached = hooked
	_update_state()
	if jump:
		reset_physics_interpolation()
		figure.snap(pos)


func reset_to(position_3d: Vector3) -> void:
	_attached = false
	_flying = false
	_anchor_body = null
	_buffered = []
	_since_throw = INF
	_update_state()
	_rope_visual.hide()
	_flight_visual.hide()
	_hide_aim()
	TimeScale.reset()
	global_position = position_3d
	velocity = Vector3.ZERO
	# A teleport, not a movement: no interpolation from the old position.
	reset_physics_interpolation()
	if figure:
		figure.snap(position_3d)
