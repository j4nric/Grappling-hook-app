extends RefCounted
## Simple autopilot for tests: it picks the throw (out of a fan of swipe
## directions) whose predicted arc sticks furthest ahead, and throws it with a
## strong flick - when no hook is out, and also near the end of a pull (chain
## throw: the rope hands over when the new hook bites).
## With nothing reachable ahead (stuck on a ledge, or falling) it takes any
## anchor.

## Flick strengths: strong (long, flat arc) and medium (shorter, drops more).
const HOOK_SPEEDS := [65.0, 42.0]
const YAWS := [0.0, -10.0, 10.0, -20.0, 20.0, -30.0, 30.0, -40.0, 40.0, -50.0, 50.0, -60.0, 60.0, -70.0, 70.0, -80.0, 80.0]
## Ignore anchors less than this far ahead (m).
const MIN_PROGRESS := 2.0
## Chain throw when the pulling anchor is this close (m), or a little more
## than the shortest rope (it never gets closer than that).
const CHAIN_DISTANCE := 7.0
## After each respawn the bot leans toward another direction (degrees of
## yaw), so it does not repeat the same fatal line forever.
const BIASES := [0.0, 25.0, -25.0, 45.0, -45.0]

## Runs are reproducible: the same level and variant always give the same
## time, whatever ran before (see reset()).
const BASE_SEED := 4242

static var _attempt := 0
static var _last_position := Vector3.ZERO
static var _fresh := true


## A new level. `variant` picks the starting preference (lean), so several
## starts of the same level fly different lines (the physics alone is
## deterministic: the same start always gives the same run).
static func reset(variant := 0) -> void:
	_attempt = variant
	_fresh = true
	# Random shakes (brittle stalactites move their collider) start alike.
	seed(BASE_SEED + variant)
	TimeScale.reset()


## Every start variant (BOT_FULL=1) or stop at the first run within bronze.
## Measuring medal times needs the full set.
static func full_runs() -> bool:
	return OS.get_environment("BOT_FULL") == "1"


## Call once per physics frame. Returns true if it threw.
static func step(p: CharacterBody3D) -> bool:
	# A jump of the position is a respawn.
	if not _fresh and p.global_position.distance_to(_last_position) > 15.0:
		_attempt += 1
	_fresh = false
	_last_position = p.global_position
	var bias: float = BIASES[_attempt % BIASES.size()]
	if p.is_hook_flying():
		return false
	var chaining: bool = p.hook_state == p.HookState.ATTACHED
	if chaining and p.global_position.distance_to(p.anchor) > maxf(CHAIN_DISTANCE, p.min_rope_length + 3.0):
		return false
	var best_score := -INF
	var best := Vector3.ZERO  # (swipe x, swipe y, hook speed)
	var fallback_score := -INF
	var fallback := Vector3.ZERO
	# A chain throw must reach clearly past the current anchor.
	var needed: float = MIN_PROGRESS + (p.global_position.z - p.anchor.z + 4.0 if chaining else 0.0)
	for speed: float in HOOK_SPEEDS:
		# The medium flick only when the strong one finds nothing ahead.
		if best_score > -INF:
			break
		for yaw_deg: float in YAWS:
			var yaw := deg_to_rad(yaw_deg)
			var swipe := Vector2(sin(yaw), -cos(yaw)) * 300.0
			var path: Dictionary = p.predict_hook_path(p._throw_direction(swipe, speed), speed)
			if not path.hit:
				continue
			var end: Vector3 = path.points[-1]
			var progress: float = p.global_position.z - end.z
			# Low anchors drag toward the depth: avoid them.
			var drop := maxf(0.0, p.global_position.y - end.y)
			var score := progress - absf(yaw_deg - bias) * 0.05 - drop * 0.5
			if score > fallback_score:
				fallback_score = score
				fallback = Vector3(swipe.x, swipe.y, speed)
			if progress >= needed and score > best_score:
				best_score = score
				best = Vector3(swipe.x, swipe.y, speed)
	if best_score == -INF:
		# Nothing ahead: standing stuck or falling into the depth, any anchor
		# beats doing nothing.
		var falling: bool = p.velocity.y < -8.0
		if chaining or fallback_score == -INF or not (p.is_on_floor() or falling):
			return false
		best = fallback
	var best_swipe := Vector2(best.x, best.y)
	InputRouter.throw_requested.emit(best_swipe, best_swipe.normalized() * best.z / p.throw_speed_per_px)
	return true
